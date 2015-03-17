package org.mskcc.cbio.importer.cvr.dmp.transformer;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.base.Function;
import com.google.common.base.Optional;
import com.google.common.base.Preconditions;
import com.google.common.collect.FluentIterable;
import org.apache.log4j.Logger;
import org.mskcc.cbio.importer.cvr.dmp.model.DmpData;
import org.mskcc.cbio.importer.cvr.dmp.model.MetaData;
import org.mskcc.cbio.importer.cvr.dmp.model.Result;
import org.mskcc.cbio.importer.cvr.dmp.model.SegmentDatum;
import org.mskcc.cbio.importer.cvr.dmp.util.DMPCommonNames;
import org.mskcc.cbio.importer.cvr.dmp.util.DmpUtils;
import org.mskcc.cbio.importer.model.CancerStudyMetadata;
import org.mskcc.cbio.importer.persistence.staging.StagingCommonNames;
import org.mskcc.cbio.importer.persistence.staging.TsvStagingFileHandler;
import org.mskcc.cbio.importer.persistence.staging.mutation.MutationFileHandlerImpl;
import org.mskcc.cbio.importer.persistence.staging.segment.SegmentModel;
import org.mskcc.cbio.importer.persistence.staging.segment.SegmentTransformer;
import org.mskcc.cbio.importer.persistence.staging.util.StagingUtils;

import javax.annotation.Nullable;
import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

/**
 * *
 *  Copyright (c) 2014 Memorial Sloan-Kettering Cancer Center.
 *
 *  This library is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY, WITHOUT EVEN THE IMPLIED WARRANTY OF
 *  MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  The software and
 *  documentation provided hereunder is on an "as is" basis, and
 *  Memorial Sloan-Kettering Cancer Center
 *  has no obligations to provide maintenance, support,
 *  updates, enhancements or modifications.  In no event shall
 *  Memorial Sloan-Kettering Cancer Center
 *  be liable to any party for direct, indirect, special,
 *  incidental or consequential damages, including lost profits, arising
 *  out of the use of this software and its documentation, even if
 *  Memorial Sloan-Kettering Cancer Center
 *  has been advised of the possibility of such damage.
 *
 * Created by criscuof on 10/28/14.
 */
class DmpSegmentDataTransformer extends SegmentTransformer implements DMPDataTransformable {
    /*
    responsible for transforming DMP segment data from model objects to
    a staging file format and invoking their output.
     */

    private final static Logger logger = Logger.getLogger(DmpSegmentDataTransformer.class);
    private final static CancerStudyMetadata csMeta =
            CancerStudyMetadata.findCancerStudyMetaDataByStableId(StagingCommonNames.IMPACT_STUDY_IDENTIFIER).get();
    private static final Boolean DELETE_FILE_FLAG = false;
    private static final String SAMPLE_ID_COLUMN = "ID";

    public DmpSegmentDataTransformer(Path stagingDirectoryPath) {
        super(stagingDirectoryPath,DELETE_FILE_FLAG, csMeta);
    }

    public DmpSegmentDataTransformer(TsvStagingFileHandler aHandler, Path stagingDirectoryPath) {
        super(aHandler);
        if (StagingUtils.isValidStagingDirectoryPath(stagingDirectoryPath)) {
            Optional<CancerStudyMetadata> csMetaOpt =
                    CancerStudyMetadata.findCancerStudyMetaDataByStableId(StagingCommonNames.IMPACT_STUDY_IDENTIFIER);
            if(csMetaOpt.isPresent()){
                this.registerStagingFileDirectory(csMetaOpt.get(), stagingDirectoryPath);
            } else {
               // this.registerStagingFileDirectory(stagingDirectoryPath);
                logger.error("Missing Cancer study metadata object");
            }
        }
    }

    @Override
    public void transform(DmpData data) {
        // the deprecated samples in the legacy data must be removed before appending
        // the new samples
        Preconditions.checkArgument(null != data, "A DmpData object is required");
        // remove any deprecated samples
        DmpUtils.removeDeprecatedSamples(data,this.tsvFileHandler,SAMPLE_ID_COLUMN);

        this.processSegments(data);
    }

    private void processSegments(DmpData data){
        List<SegmentModel> segmentModelList = FluentIterable.from(data.getResults())
                .transformAndConcat(new Function<Result, List<SegmentDatum>>() {
            @Nullable
            @Override
            public List<SegmentDatum> apply(@Nullable Result result) {
                String sampleId= result.getMetaData().getDmpSampleId();
                for (SegmentDatum sd  : result.getSegmentData()){
                    sd.setID(sampleId);
                }
                return result.getSegmentData();
            }
        })
                .transform(new Function<SegmentDatum,SegmentModel>(){
                    @Nullable
                    @Override
                    public SegmentModel apply(@Nullable SegmentDatum segmentData) {

                        return new DmpSegmentModel(segmentData);
                    }
                }).toList();

        // output the list of SegmentData objects to the staging file
        this.tsvFileHandler.transformImportDataToTsvStagingFile(segmentModelList, SegmentModel.getTransformationModel());
        //this.fileHandler.transformImportDataToTsvStagingFile(segmentModelList, SegmentModel.getTransformationModel());
    }

    // main method for stand alone testing
    public static void main(String...args){
        ObjectMapper OBJECT_MAPPER = new ObjectMapper();
        String tempDir = "/tmp/cvr/dmp";
        File tmpDir = new File(tempDir);
        tmpDir.mkdirs();
        Path stagingFileDirectory = Paths.get(tempDir);

        DmpSegmentDataTransformer transformer = new DmpSegmentDataTransformer(stagingFileDirectory);

        try {
            DmpData data = OBJECT_MAPPER.readValue(new File("/tmp/dmp_ws.json"), DmpData.class);
            transformer.transform(data);

        } catch (IOException ex) {
            logger.error(ex.getMessage());
            ex.printStackTrace();
        }
    }

}
