package org.mskcc.cbio.importer.cvr.dmp.transformer;

import com.google.common.base.Preconditions;
import org.apache.log4j.Logger;
import org.mskcc.cbio.importer.cvr.dmp.model.StructuralVariant;
import org.mskcc.cbio.importer.persistence.staging.structvariant.StructVariantModel;

/**
 * Copyright (c) 2014 Memorial Sloan-Kettering Cancer Center.
 * <p/>
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY, WITHOUT EVEN THE IMPLIED WARRANTY OF
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  The software and
 * documentation provided hereunder is on an "as is" basis, and
 * Memorial Sloan-Kettering Cancer Center
 * has no obligations to provide maintenance, support,
 * updates, enhancements or modifications.  In no event shall
 * Memorial Sloan-Kettering Cancer Center
 * be liable to any party for direct, indirect, special,
 * incidental or consequential damages, including lost profits, arising
 * out of the use of this software and its documentation, even if
 * Memorial Sloan-Kettering Cancer Center
 * has been advised of the possibility of such damage.
 * <p/>
 * Created by criscuof on 1/30/15.
 * mod 2/4/2015 added suppor for addition attributes provided by Web service
 */
public class DmpStructVariantModel extends StructVariantModel {

    private final StructuralVariant structVariant;
    private final static Logger logger = Logger.getLogger(DmpStructVariantModel.class);

    public DmpStructVariantModel( StructuralVariant sv){
        Preconditions.checkArgument(null != sv, "A StructuralVariant object is required");
        this.structVariant = sv;
    }

    @Override
    public String getTumorId() {
        return structVariant.getDmpSampleId();
    }

    @Override
    public String getChromosome1() {
        return structVariant.getSite1Chrom();
    }

    @Override
    public String getPosition1() {
        return structVariant.getSite1Pos().toString();
    }

    @Override
    public String getChromosome2() {
        return structVariant.getSite2Chrom();
    }

    @Override
    public String getPosition2() {
        return structVariant.getSite2Pos().toString();
    }

    @Override
    public String getsvType() {
        return structVariant.getSvClassName();
    }

    @Override
    public String getGene1() {
        return structVariant.getSite1Gene();
    }

    @Override
    public String getGene2() {
        return structVariant.getSite2Gene();
    }

    @Override
    public String getSite1Description() {
        return structVariant.getSite1Desc();
    }

    @Override
    public String getSite2Description() {
        return structVariant.getSite2Desc();
    }

    @Override
    public String getFusion() {
        return structVariant.getEventInfo();
    }

    @Override
    public String getConnectionType() {
        return structVariant.getConnectionType();
    }

    @Override
    public String getSvLength() {
        return structVariant.getSvLength().toString();
    }

    @Override
    public String getMapq() {
        return (structVariant.getMapq() != null)? structVariant.getMapq().toString():"";
    }

    @Override
    public String getPairEndReadSupport() {
        return  (structVariant.getPairedEndReadSupport() != null)?structVariant.getPairedEndReadSupport().toString():"";
    }

    @Override
    public String getSplitReadSupport() {
        return (structVariant.getSplitReadSupport()!=null) ? structVariant.getSplitReadSupport().toString():"";
    }

    @Override
    public String getBrkptType() {
        return structVariant.getBreakpointType();
    }

    @Override
    public String getConsensusSequence() {
        return "";
    }

    @Override
    public String getTumorVariantCount() {
        return (structVariant.getTumorVariantCount()!=null)? structVariant.getTumorVariantCount().toString():"";
    }

    @Override
    public String getTumorReadCount() {
        return (structVariant.getTumorReadCount() !=null)?structVariant.getTumorReadCount().toString():"";
    }

    @Override
    public String getTumorGenotypeQScore() {
        return "";
    }

    @Override
    public String getNormalVariantCount() {
        return (structVariant.getNormalVariantCount()!=null) ? structVariant.getNormalVariantCount().toString():"";
    }

    @Override
    public String getNormalReadCount() {
        return (structVariant.getNormalReadCount()!=null)?structVariant.getNormalReadCount().toString():"";
    }

    @Override
    public String getNormalGenotypeQScore() {
        return "";
    }
}
