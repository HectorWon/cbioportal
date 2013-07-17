/*
 * Copyright (c) 2012 Memorial Sloan-Kettering Cancer Center.
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2.1 of the License, or
 * any later version.
 *
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
 * has been advised of the possibility of such damage.  See
 * the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
 */

/**
 *
 * - Generate the plots tab "global" data object (Being used in every sub tabs)
 * - AJAX data retrieving function (using JSON servlet)
 * - Cache every generated data set in a global variable
 *
 */

var Plots = (function(){

    var genetic_profiles = {
            genetic_profile_mutations : [],
            genetic_profile_mrna : [],
            genetic_profile_copy_no : [],
            genetic_profile_rppa : [],
            genetic_profile_dna_methylation : []
        };

    function getGeneticProfileCallback(result) {

        for (var key in result) {
            var obj = result[key];
            var profile_type = obj.GENETIC_ALTERATION_TYPE;
            if (profile_type === "MUTATION_EXTENDED") {
                genetic_profiles.genetic_profile_mutations.push([obj.STABLE_ID, obj.NAME]);
            } else if(profile_type === "COPY_NUMBER_ALTERATION") {
                genetic_profiles.genetic_profile_copy_no.push([obj.STABLE_ID, obj.NAME]);
            } else if(profile_type === "MRNA_EXPRESSION") {
                genetic_profiles.genetic_profile_mrna.push([obj.STABLE_ID, obj.NAME]);
            } else if(profile_type === "METHYLATION") {
                genetic_profiles.genetic_profile_dna_methylation.push([obj.STABLE_ID, obj.NAME]);
            } else if(profile_type === "PROTEIN_ARRAY_PROTEIN_LEVEL") {
                genetic_profiles.genetic_profile_rppa.push([obj.STABLE_ID, obj.NAME]);
            }
        }

        PlotsMenu.init();
        PlotsMenu.update();
        PlotsTwoGenesMenu.init();
        PlotsTwoGenesMenu.update();
        PlotsCustomMenu.init();
        PlotsCustomMenu.update();
        PlotsView.init();

        $('#plots-menus').bind('tabsshow', function(event, ui) {
            if (ui.index === 0) {
                PlotsView.init();
            } else if (ui.index === 1) {
                PlotsTwoGenesView.init();
            } else if (ui.index === 2) {
                PlotsCustomView.init();
            } else {
                //TODO: error handle
            }
        });

    }

    return {
        init: function() {
            var paramsGetProfiles = {
                cancer_study_id: cancer_study_id
            };
            $.post("getGeneticProfile.json", paramsGetProfiles, getGeneticProfileCallback, "json");
        },
        getGeneticProfiles: function() {
            return genetic_profiles;
        },
        getProfileData: function(gene, genetic_profile_id, case_set_id, case_ids_key, callback_func) {
            var paramsGetProfileData = {
                gene_list: gene,
                genetic_profile_id: genetic_profile_id,
                case_set_id: case_set_id,
                case_ids_key: case_ids_key
            };
            $.post("getProfileData.json", paramsGetProfileData, callback_func, "json");
        },
        getMutationType: function(gene, genetic_profile_id, case_set_id, case_ids_key, callback_func) {
            var paramsGetMutationType = {
                geneList: gene,
                geneticProfiles: genetic_profile_id,  //Here is simply cancer_study_id + "_mutations"
                caseSetId: case_set_id,
                caseIdsKey: case_ids_key
            };
            $.post("getMutationData.json", paramsGetMutationType, callback_func, "json");
        }
    };

}());    //Closing Plots









