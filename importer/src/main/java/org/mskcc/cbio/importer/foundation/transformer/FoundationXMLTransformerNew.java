package org.mskcc.cbio.importer.foundation.transformer;

import com.google.common.base.*;
import com.google.common.collect.FluentIterable;
import com.google.common.collect.HashBasedTable;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

import com.google.common.collect.Table;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.Serializable;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import static java.nio.file.StandardOpenOption.APPEND;
import static java.nio.file.StandardOpenOption.CREATE;
import static java.nio.file.StandardOpenOption.DSYNC;

import java.util.*;
import javax.xml.bind.JAXBElement;
import org.apache.log4j.Logger;
import org.mskcc.cbio.foundation.jaxb.*;
import org.mskcc.cbio.importer.Config;
import org.mskcc.cbio.importer.FileTransformer;
import org.mskcc.cbio.importer.IDMapper;
import org.mskcc.cbio.importer.dmp.util.DmpUtils;
import org.mskcc.cbio.importer.foundation.extractor.FileDataSource;
import org.mskcc.cbio.importer.foundation.support.CasesTypeSupplier;
import org.mskcc.cbio.importer.foundation.support.CommonNames;

import org.mskcc.cbio.importer.model.FoundationMetadata;
import org.mskcc.cbio.importer.persistence.staging.*;

import org.mskcc.cbio.importer.util.GeneSymbolIDMapper;
import scala.Tuple2;
import scala.Tuple3;

/*
 responsible for transforming one or more XML files representing Foundation
 studies in a directory to cbio staging files
 Transformation steps: 
 1. delete any existing staging files
 2. create new instances of staging files
 3. for each XML file within the directory
 a. unmarshal XML to JAXB object graph
 b. for each case in object graph
 i. filter out excluded cases
 ii. transform Java class attribute values to values in a staging file record
 iii. append staging file record to appropriate staging file
 4. close staging files
    
 */
public class FoundationXMLTransformerNew implements FileTransformer {

    private String xmlFilename;
    private static final Logger logger = Logger.getLogger(FoundationXMLTransformerNew.class);
    private static final Joiner tabJoiner = Joiner.on('\t').useForNull(" ");
    private final Joiner pathJoiner = Joiner.on(System.getProperty("file.separator"));
    private static final Splitter posSplitter = Splitter.on(':');
    private static final Splitter blankSplitter = Splitter.on(' ').omitEmptyStrings();
    private FoundationStagingFileManager fileManager;
    //TODO: move these to Spring config file
    // common file handler responsible for generating MAF files
    private final MafFileHandler mafFileHandler = new MutationFileHandlerImpl();
    // common file handler for generating CNV files
    private final CnvFileHandler cnvFileHandler = new CnvFileHandlerImpl();

    private Table<String, String, Double> cnaTable;
    // instantiate the transformation map supplier
    private final Supplier<Map<String, Tuple3<Function<Tuple2<String, Optional<String>>, String>, String, Optional<String>>>> transformationMaprSupplier =
            Suppliers.memoize(new FoundationMutationsTransformationMapSupplier());

    // use IDMapper for HUGO <-> Entrez conversions
    private  IDMapper geneMapper;

    private Supplier<CasesType> casesTypeSupplier;

    private final Config config;

    public FoundationXMLTransformerNew(Config aConfig) {
        Preconditions.checkArgument(null != aConfig, "A Config object is required");

        this.config = aConfig;
        //TODO: make constructor argument
        this.geneMapper = new GeneSymbolIDMapper();
    }

    /*
     mod 03Oct2014 - modify transformer to process all XML files within the
     specified Path (i.e. directory). The transformation types (e.g. mutations)
     from all files within the directory will be written to the same staging file

     mod 03Nov2014 - modified to support output pf mutations (i.e. short variants) using
     an implementation of the MafFileHandler interface. This required the definition of a set of
     transformation functions utilizing "getter" methods within the ShortVariantType model object
    
     This version also supports filtering out the excluded cases specified in
     the Config object
    
     Use the FoundationStagingFileManager inner class to handle I/O operations
     to the staging files
     */

    @Override
    public void transform(FileDataSource xmlSource) {
        Preconditions.checkArgument(null != xmlSource,
                "A FileDataSource for XML input files is required");
        Preconditions.checkArgument(!xmlSource.getFilenameList().isEmpty(),
                "The FileDataSource does not contain any XML files");
        // instantiate a new FoundationStagingFileManager
        this.fileManager
                = new FoundationStagingFileManager(Paths.get(xmlSource.getDirectoryName()));
        // register the data source and column names with the maf file handler
        //TODO: refactor file names to properties file
        Path mafPath = Paths.get(xmlSource.getDirectoryName()).resolve("data_mutations_extended.txt");
        this.mafFileHandler.registerMafStagingFile(mafPath,this.resolveColumnNames());
        this.cnvFileHandler.initializeFilePath(Paths.get(xmlSource.getDirectoryName())
                .resolve("data_CNA.txt"));

        // the CNA table must be persisted across all the XML files in a study
        this.cnaTable = HashBasedTable.create();
        // process each xml file in the study's staging directory
        for (Path xmlPath : xmlSource.getFilenameList()) {
            Optional<FoundationMetadata> metadataOptional =
                    this.resolveFoundationMetadataFromXMLFilename(xmlPath.getFileName().toString());
            if( metadataOptional.isPresent()) {
                this.casesTypeSupplier = Suppliers.memoize(new CasesTypeSupplier(xmlPath.toString(),
                        metadataOptional.get()));
                this.processFoundationData();
            } else {
                logger.error("File "+ xmlPath.toString() +" cannot be associated with a cancer study");
            }
        }
        // the CNA report can only be generated after all the XML files have been processed
        this.cnvFileHandler.persistCnvTable(cnaTable);
    }
    // resolve the FoundationMetadata object for this study
    private Optional<FoundationMetadata> resolveFoundationMetadataFromXMLFilename(final String filename) {
        final Collection<FoundationMetadata> mdc = config.getFoundationMetadata();
        final List<String> fileList = Lists.newArrayList(filename);
       return  FluentIterable.from(mdc)
                .firstMatch(new Predicate<FoundationMetadata>() {
                    @Override
                    public boolean apply(final FoundationMetadata meta) {
                        List<String> fl = FluentIterable.from(fileList).filter(meta.getRelatedFileFilter()).toList();
                        return (!fl.isEmpty());

                    }
                });

    }


    private List<String> resolveColumnNames() {
        return FluentIterable.from(this.transformationMaprSupplier.get().keySet())
                .transform(new Function<String, String>() {
                    @Override
                    public String apply(String s) {
                        return (s.substring(3)); // strip off the three digit numeric prefix
                    }
                }).toList();
    }

    @Override
    public void transform(Path aPath) throws IOException {

    }

    private void processFoundationData() {


        this.generateDatMutationsExtendedReport();
        this.generateCNATable();
        this.generateClinicalDataReport();
        this.generateFusionDataReport();
    }


    Function<JAXBElement, Tuple2<String, Double>> cnaFumction = new Function<JAXBElement, Tuple2<String, Double>>() {
        @Override
        public Tuple2<String, Double> apply(JAXBElement je) {
            CopyNumberAlterationType cna = (CopyNumberAlterationType) je.getValue();
            switch (cna.getType()) {
                case CommonNames.CNA_AMPLIFICATION:
                    return new Tuple2(cna.getGene(), CommonNames.CNA_AMPLIFICATION_VALUE);
                case CommonNames.CNA_LOSS:
                    return new Tuple2(cna.getGene(), CommonNames.CNA_LOSS_VALUE);
                default:
                    return new Tuple2(cna.getGene(), CommonNames.CNA_DEFAULT_VALUE);
            }
        }
    };

    private void generateCNATable() {
        CasesType casesType = this.casesTypeSupplier.get();

        for (CaseType ct : casesType.getCase()) {
            VariantReportType vrt = ct.getVariantReport();
            CopyNumberAlterationsType cnat = vrt.getCopyNumberAlterations();
            if (null != cnat) {
                for (Tuple2<String, Double> cnaTuple : FluentIterable
                        .from(cnat.getContent())
                        .filter(JAXBElement.class)
                        .transform(cnaFumction)
                        .toList()) {
                    this.cnaTable.put(cnaTuple._1(), ct.getCase(), cnaTuple._2());
                }
            }
        }
    }


    private String fusionCase;

    private void generateFusionDataReport() {
        CasesType casesType = this.casesTypeSupplier.get();

        for (CaseType caseType : casesType.getCase()) {
            // put case id into global scope
            this.fusionCase = caseType.getCase();
            List<Serializable> contentList = caseType.getVariantReport().getRearrangements().getContent();
            if (contentList.size() > 0) {
                List<JAXBElement> jaxbList = Lists.newArrayList(Iterables.filter(contentList, JAXBElement.class));
                this.fileManager.generateDataReport(CommonNames.FUSION_REPORT_TYPE, jaxbList, rearrangementDataFunction);
            }
        }

    }
    /**
     * function to transform a collection of JAXBElement objects representing
     * RearrangementType XML elements into a collection of tab-delimited String
     * objects
     */
    Function<JAXBElement, String> rearrangementDataFunction = new Function<JAXBElement, String>() {
        @Override
        public String apply(JAXBElement je) {
            List<String> attributeList = Lists.newArrayList();
            RearrangementType rt = (RearrangementType) je.getValue();
            attributeList.add(rt.getTargetedGene());
            attributeList.add(""); // place holder for Entrez id
            attributeList.add(CommonNames.CENTER_FOUNDATION);
            attributeList.add(fusionCase);
            attributeList.add(rt.getTargetedGene() + "-" + rt.getOtherGene());
            attributeList.add(CommonNames.DEFAULT_FUSION);
            attributeList.add(CommonNames.DEFAULT_DNA_SUPPORT);
            attributeList.add(CommonNames.DEFAULT_RNA_SUPPORT);
            attributeList.add(CommonNames.DEFAULT_FUSION_METHOD);
            attributeList.add(parseFusionFrame(rt));
            return tabJoiner.join(attributeList);
        }

    };

    private String parseFusionFrame(RearrangementType rt) {
        if (Strings.isNullOrEmpty(rt.getInFrame()) || rt.getInFrame().equals(CommonNames.UNKNOWN)) {
            return CommonNames.UNKNOWN;
        }
        return (rt.getInFrame().equals("No")) ? CommonNames.OUT_OF_FRAME : CommonNames.IN_FRAME;
    }

    /**
     * Function to map attributes within a CaseType instance to a tab-delimited
     * String containing clinical data
     */
    Function<CaseType, String> clinicalDataFunction = new Function<CaseType, String>() {

        @Override
        public String apply(CaseType caseType) {
            List<String> attributeList = Lists.newArrayList();
            attributeList.add(caseType.getCase());
            attributeList.add(caseType.getVariantReport().getGender());
            attributeList.add(caseType.getFmiCase());
            attributeList.add(caseType.getVariantReport().getPipelineVersion());
            attributeList.add(displayMetricValue(caseType, CommonNames.METRIC_TUMOR_NUCLEI_PERCENT));  // not supported in current data
            attributeList.add(displayMetricValue(caseType, CommonNames.METRIC_MEDIAN_COVERAGE));
            attributeList.add(displayMetricValue(caseType, CommonNames.METRIC_COVERAGE_GT_100));
            //There are two (2) Error metrics; the first is the DNA error rate, the second is the RNA error rate
            // This application captures the first (i.e. DNA)
            attributeList.add(displayMetricValue(caseType, CommonNames.METRIC_ERROR));
            return tabJoiner.join(attributeList);
        }
    };

    /**
     * private method to generate the data_clinical.txt report
     *
     */
    private void generateClinicalDataReport() {
        CasesType casesType = this.casesTypeSupplier.get();
        this.fileManager.generateDataReport(CommonNames.CLINICAL_REPORT_TYPE,
                casesType.getCase(), clinicalDataFunction);
    }
    /*
     private method to generate mutation report from short variant elements
     */



    private void generateDatMutationsExtendedReport() {
        // add the sample id to each short variant
        List<ShortVariantType> svtList =this.transformShortVariants();
        this.mafFileHandler.transformImportDataToStagingFile(svtList, transformationFunction);

    }

    /*
    Function to transform DMP SNP attributes from a Short Variant object into MAF attributes collected in
    a tsv String for subsequent output
    */
    Function<ShortVariantType, String> transformationFunction = new Function<ShortVariantType, String>() {
        @Override
        public String apply(final ShortVariantType svt) {
            Set<String> attributeList = transformationMaprSupplier.get().keySet();
            List<String> mafAttributes = FluentIterable.from(attributeList)
                    .transform(new Function<String, String>() {
                        @Override
                        public String apply(String attribute) {
                            Tuple3<Function<Tuple2<String, Optional<String>>, String>, String, Optional<String>> tuple3
                                    = transformationMaprSupplier.get().get(attribute);
                            String attribute1 = DmpUtils.pojoStringGetter(tuple3._2(), svt);

                            Optional<String> optAttribute2 = (Optional<String>) ((tuple3._3().isPresent())
                                    ? Optional.of(DmpUtils.pojoStringGetter(tuple3._3().get(), svt))
                                    : Optional.absent());

                            return tuple3._1().apply(new Tuple2(attribute1, optAttribute2));

                        }
                    }).toList();
            String retRecord = tabJoiner.join(mafAttributes);

            return retRecord;
        }

    };

    /*
    we need to add the sample id attribute to each short variant so that they can be processed
    independently
     */
    private List<ShortVariantType> transformShortVariants() {
        List<CaseType> caseTypeList = this.casesTypeSupplier.get().getCase();
        List<ShortVariantType> transformedList = Lists.newArrayList();
        for(CaseType caseType : caseTypeList){
            String sampleId = caseType.getCase();
            List<ShortVariantType> svtList = caseType.getVariantReport().getShortVariants().getShortVariant();
            for (ShortVariantType svt : svtList) {
                svt.setValue(sampleId);
            }
            transformedList.addAll(svtList);
        }
        return transformedList;
    }

    @Override
    /*
     * The primary identifier for Foundation Medicine cases is the study id
     */
    public String getPrimaryIdentifier() {
        CasesType casesType = this.casesTypeSupplier.get();
        // get the study from the first case
        return casesType.getCase().get(0).getVariantReport().getStudy();
    }

    @Override
    /*
     * the prrimary entity for Foundation Medicine XML data is the Case
     */
    public Integer getPrimaryEntityCount() {
        CasesType casesType = this.casesTypeSupplier.get();
        return casesType.getCase().size();
    }

    public String getStudyId() {
        CasesType casesType = this.casesTypeSupplier.get();
        // get the study from the first case
        return casesType.getCase().get(0).getVariantReport().getStudy();
    }

    /**
     * private method to provide a String representation of a Metric value
     *
     * @param caseType
     * @param metricName
     * @return
     */
    private String displayMetricValue(CaseType caseType, String metricName) {
        MetricsType metricsType = caseType.getVariantReport().getQualityControl().getMetrics();
        for (MetricType metric : metricsType.getMetric()) {
            if (metric.getName().equals(metricName)) {
                return metric.getMetricTypeValue();
            }
        }

        return "";
    }


    /*
     a private inner class to manage interactions with the staging files
     for each study
     */
    private class FoundationStagingFileManager {

        private final Path stagingFilePath;
        private Map<String, Path> stagingReportWriterPath = Maps.newConcurrentMap();
        private Map<String, List<String>> reportHeadingsMap = Maps.newConcurrentMap();
        private final Map<String, String> reportFileMap
                = Maps.newConcurrentMap();

        /*
         BufferedWriter writer = Files.newBufferedWriter(
         aPath, Charset.defaultCharset()))
         */
        public FoundationStagingFileManager(Path aPath) {

            this.stagingFilePath = aPath;

            reportFileMap.put(CommonNames.CLINICAL_REPORT_TYPE, "data_clinical.txt");
            reportFileMap.put(CommonNames.FUSION_REPORT_TYPE, "data_fusions.txt");

            //reportHeadingsMap.put(CommonNames.MUTATION_REPORT_TYPE, Arrays.asList(CommonNames.MUTATIONS_REPORT_HEADINGS));
            //reportHeadingsMap.put(CommonNames.CLINICAL_REPORT_TYPE, Arrays.asList(CommonNames.CLINICAL_DATA_HEADINGS));
            reportHeadingsMap.put(CommonNames.FUSION_REPORT_TYPE, Arrays.asList(CommonNames.FUSION_DATA_HEADINGS));
            this.resolveStagingReportWriterPathMap();
        }

        /*
         create a Map of report specific file paths, create the report files and
         write out any report headings
         */
        private void resolveStagingReportWriterPathMap() {
            for (Map.Entry<String, String> entry : reportFileMap.entrySet()) {
                try {
                    Path reportPath = Paths.get(pathJoiner.join(stagingFilePath.toString(), entry.getValue()));
                    this.createNewStagingFile(reportPath);
                    this.stagingReportWriterPath.put(entry.getKey(), reportPath);
                    // write out any report headings
                    if (reportHeadingsMap.containsKey(entry.getKey())) {
                        BufferedWriter writer = Files.newBufferedWriter(reportPath, Charset.defaultCharset());
                        writer.append(tabJoiner.join(reportHeadingsMap.get(entry.getKey())));
                        writer.newLine();
                        writer.flush();
                    }
                } catch (IOException ex) {
                    logger.error(ex.getMessage());
                }
            }
        }

        private void generateDataReport(String reportType, List aList, Function aFunction) {
            if (this.stagingReportWriterPath.containsKey(reportType)) {
                Path aPath = this.stagingReportWriterPath.get(reportType);
                OpenOption[] options = new OpenOption[]{CREATE, APPEND, DSYNC};
                // create the file if it doesn't exist, append to it if it does
                try {
                    Files.write(aPath, Lists.transform(aList, aFunction), Charset.defaultCharset(), options);
                } catch (IOException ex) {
                    logger.error(ex.getMessage());
                }
            } else {
                logger.error(reportType + " is not a supported report type.");
            }
        }

        /*
         create a new staging file for this study
         delete an older ones if it exist
         */
        private void createNewStagingFile(Path path) throws IOException {
            Files.deleteIfExists(path);
            Files.createFile(path); // accept default file attributes
            logger.info("Staging file " + path.toString() + " created");
        }


    }



}