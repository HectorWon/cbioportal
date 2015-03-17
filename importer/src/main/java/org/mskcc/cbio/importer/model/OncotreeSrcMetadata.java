package org.mskcc.cbio.importer.model;

import com.google.common.base.Optional;
import com.google.common.base.Strings;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Lists;

import com.google.gdata.data.spreadsheet.Worksheet;
import com.google.gdata.data.spreadsheet.WorksheetEntry;
import com.mysql.jdbc.StringUtils;
import org.apache.commons.beanutils.BeanUtils;
import org.apache.log4j.Logger;
import org.mskcc.cbio.importer.config.internal.ImporterSpreadsheetService;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;
import java.util.Map;


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
 * Created by criscuof on 1/18/15.
 */
public class OncotreeSrcMetadata {
    /*
    A POJO to represent rows from the importer speadsheet oncotree worksheet
    field names conform to Google API mapping standards
    fields can't be final because of constructor argument, but no setters are provided
    */

    private static final Logger logger = Logger.getLogger(OncotreeSrcMetadata.class);
    public static final String worksheetName = MetadataCommonNames.Worksheet_OncotreeSrc;

    private String primary;
    private String secondary;
    private String tertiary;
    private String quaternary;
    private String metamaintype;

    public OncotreeSrcMetadata(Map<String, String> worksheetRowMap) {
        this.setPrimary(worksheetRowMap.get("primary"));
        this.setSecondary(worksheetRowMap.get("secondary"));
        this.setTertiary(worksheetRowMap.get("teriary"));
        this.setQuaternary(worksheetRowMap.get("quaternary"));
        this.setMetamaintype(worksheetRowMap.get("metamaintype"));
    }

    private final ImmutableMap<String, String> getterMap = new ImmutableMap.Builder<String, String>()
            .put("primary", "getPrimary")
            .put("secondary", "getSecondary")
            .put("tertiary", "getTertiary")
            .put("quaternary", "getQuaternary")
            .put("metamaintype","getMetamaintype")
            .build();

    public Optional<String> getAttributeByName (String attributeName){
        if(Strings.isNullOrEmpty(attributeName) ||
                !getterMap.keySet().contains(attributeName )) {return Optional.absent(); }
        String getterName = getterMap.get(attributeName);
        try {
            Method getterMethod = this.getClass().getMethod(getterName);
            return  Optional.of((String) getterMethod.invoke(this));
        } catch (Exception e) {
            logger.error(e.getMessage());
        }
        return Optional.absent();
    }

    public String getPrimary() {
        return primary;
    }

    public String getSecondary() {
        return secondary;
    }

    public String getTertiary() {
        return tertiary;
    }

    public String getQuaternary() {
        return quaternary;
    }

    public String getMetamaintype() { return metamaintype;}
    // main method for stand alone testing
    public static void main (String...args) {
        try {
            Optional<Map<String,String >> rowOptional = ImporterSpreadsheetService.INSTANCE.getWorksheetRowByColumnValue(MetadataCommonNames.Worksheet_OncotreeSrc,
                    "quaternary", "Uterine Leiomyoma (ULM)");
            if(rowOptional.isPresent()){
                OncotreeSrcMetadata onco = new OncotreeSrcMetadata(rowOptional.get());
                System.out.println(onco.getMetamaintype());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public void setPrimary(String primary) {
        this.primary = primary;
    }

    public void setSecondary(String secondary) {
        this.secondary = secondary;
    }

    public void setTertiary(String tertiary) {
        this.tertiary = tertiary;
    }

    public void setQuaternary(String quaternary) {
        this.quaternary = quaternary;
    }

    public void setMetamaintype(String metamaintype) {
        this.metamaintype = metamaintype;
    }
}

