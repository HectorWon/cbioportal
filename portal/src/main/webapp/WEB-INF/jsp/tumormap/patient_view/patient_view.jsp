<%@ page import="org.mskcc.cbio.portal.servlet.QueryBuilder" %>
<%@ page import="org.mskcc.cbio.portal.servlet.PatientView" %>
<%@ page import="org.mskcc.cbio.portal.servlet.DrugsJSON" %>
<%@ page import="org.mskcc.cbio.cgds.model.CancerStudy" %>
<%@ page import="org.mskcc.cbio.cgds.model.GeneticProfile" %>
<%@ page import="org.mskcc.cbio.portal.util.SkinUtil" %>
<%@ page import="java.util.Map" %>
<%@ page import="org.json.simple.JSONValue" %>


<%
boolean print = "1".equals(request.getParameter("print"));
request.setAttribute("tumormap", true);
String caseId = (String)request.getAttribute(PatientView.CASE_ID);
String patientViewError = (String)request.getAttribute(PatientView.ERROR);
CancerStudy cancerStudy = (CancerStudy)request.getAttribute(PatientView.CANCER_STUDY);
String jsonClinicalData = JSONValue.toJSONString((Map<String,String>)request.getAttribute(PatientView.CLINICAL_DATA));

String tissueImageUrl = (String)request.getAttribute(PatientView.TISSUE_IMAGES);
boolean showTissueImages = tissueImageUrl!=null;

String patientID = (String)request.getAttribute(PatientView.PATIENT_ID_ATTR_NAME);
String pathReportUrl = (String)request.getAttribute(PatientView.PATH_REPORT_URL);

String drugType = request.getParameter("drug_type");

GeneticProfile mutationProfile = (GeneticProfile)request.getAttribute(PatientView.MUTATION_PROFILE);
boolean showMutations = mutationProfile!=null;

GeneticProfile cnaProfile = (GeneticProfile)request.getAttribute(PatientView.CNA_PROFILE);
boolean showCNA = cnaProfile!=null;

GeneticProfile mrnaProfile = (GeneticProfile)request.getAttribute(PatientView.MRNA_PROFILE);

String isDemoMode = request.getParameter("demo");
boolean showPlaceHoder;
if (isDemoMode!=null) {
    showPlaceHoder = isDemoMode.equalsIgnoreCase("on");
} else {
    showPlaceHoder = SkinUtil.showPlaceholderInPatientView();
}

boolean showPathways = showPlaceHoder & (showMutations | showCNA);
boolean showSimilarPatient = showPlaceHoder & (showMutations | showCNA);

boolean hasCnaSegmentData = ((Boolean)request.getAttribute(PatientView.HAS_SEGMENT_DATA));
boolean hasAlleleFrequencyData =  ((Boolean)request.getAttribute(PatientView.HAS_ALLELE_FREQUENCY_DATA));
boolean showGenomicOverview = showMutations | hasCnaSegmentData;
boolean showClinicalTrials = true;
boolean showDrugs = true;

double[] genomicOverviewCopyNumberCnaCutoff = SkinUtil.getPatientViewGenomicOverviewCnaCutoff();

int numPatientInSameStudy = 0;
int numPatientInSameMutationProfile = 0;
int numPatientInSameCnaProfile = 0;

boolean noData = cnaProfile==null & mutationProfile==null;

String mutationProfileStableId = null;
String cnaProfileStableId = null;
String mrnaProfileStableId = null;
if (mutationProfile!=null) {
    mutationProfileStableId = mutationProfile.getStableId();
}
if (cnaProfile!=null) {
    cnaProfileStableId = cnaProfile.getStableId();
}
if (mrnaProfile!=null) {
    mrnaProfileStableId = mrnaProfile.getStableId();
}

if (patientViewError!=null) {
    out.print(caseId);
    out.print(": ");
    out.println();
    out.print(patientViewError);
} else {
    numPatientInSameStudy = (Integer)request.getAttribute(PatientView.NUM_CASES_IN_SAME_STUDY);
    if (mutationProfile!=null) {
        numPatientInSameMutationProfile = (Integer)request.getAttribute(
                PatientView.NUM_CASES_IN_SAME_MUTATION_PROFILE);
    }
    if (cnaProfile!=null) {
        numPatientInSameCnaProfile = (Integer)request.getAttribute(
                PatientView.NUM_CASES_IN_SAME_CNA_PROFILE);
    }
%>

<jsp:include page="../../global/header.jsp" flush="true" />

<%if(patientID!=null) {%>
    <p style="background-color: lightyellow;"> This patient has 
        <a title="Go to multi-sample view" href="case.do?cancer_study_id=<%=cancerStudy.getCancerStudyStableId()%>&patient_id=<%=patientID%>">multiple tumors</a>.
    </p>
<%}%>

<div id="clinical_div">
</div>


<div id="patient-tabs">
    <ul>
        
    <li><a href='#summary' class='patient-tab'>Summary</a></li>
    
    <%if(showMutations){%>
    <li><a href='#mutations' class='patient-tab'>Mutations</a></li>
    <%}%>
    
    <%if(showCNA){%>
    <li><a href='#cna' class='patient-tab'>Copy Number Alterations</a></li>
    <%}%>

    <%if(showDrugs){%>
    <li><a href='#drugs' class='patient-tab'>Drugs</a></li>
    <%}%>

    <%if(showClinicalTrials){%>
    <li><a href='#clinical-trials' class='patient-tab'>Clinical Trials</a></li>
    <%}%>
    
    <%if(showTissueImages){%>
    <li><a id="link-tissue-images" href='#images' class='patient-tab'>Tissue Images</a></li>
    <%}%>
    
    <%if(pathReportUrl!=null){%>
    <li><a href='#path-report' class='patient-tab'>Pathology Report</a></li>
    <%}%>

    <%if(showPathways){%>
    <li><a href='#pathways' class='patient-tab'>Network</a></li>
    <%}%>
    
    <%if(showSimilarPatient){%>
    <li><a href='#similar-patients' class='patient-tab'>Similar Patients</a></li>
    <%}%>

    </ul>

    <div class="patient-section" id="summary">
        <%@ include file="summary.jsp" %>
    </div>

    <%if(showMutations){%>
    <div class="patient-section" id="mutations">
        <%@ include file="mutations.jsp" %>
    </div>
    <%}%>

    <%if(showCNA){%>
    <div class="patient-section" id="cna">
        <%@ include file="cna.jsp" %>
    </div>
    <%}%>

    <%if(showTissueImages){%>
    <div class="patient-section" id="images">
        <%@ include file="tissue_images.jsp" %>
    </div>
    <%}%>

    <%if(pathReportUrl!=null){%>
    <div class="patient-section" id="path-report">
        <%@ include file="path_report.jsp" %>
    </div>
    <%}%>

    <%if(showPathways){%>
    <div class="patient-section" id="pathways">
        <%@ include file="pathways.jsp" %>
    </div>
    <%}%>

    <%if(showSimilarPatient){%>
    <div class="patient-section" id="similar-patients">
        <%@ include file="similar_patients.jsp" %>
    </div>
    <%}%>

    <%if(showDrugs){%>
    <div class="patient-section" id="drugs">
        <%@ include file="drugs.jsp" %>
    </div>
    <%}%>

    <%if(showClinicalTrials){%>
        <div class="patient-section" id="clinical-trials">
            <%@ include file="clinical_trials.jsp" %>
        </div>
    <%}%>

</div>
<%  
}
%>
        </div>
    </td>
</tr>

<tr>
    <td colspan="3">
	<jsp:include page="../../global/footer.jsp" flush="true" />
    </td>
</tr>

</table>
</center>
</div>
<jsp:include page="../../global/xdebug.jsp" flush="true" />

<link href="css/jquery.qtip.min.css" type="text/css" rel="stylesheet"/>

<style type="text/css" title="currentStyle"> 
        @import "css/data_table_jui.css";
        @import "css/data_table_ColVis.css";
        .ColVis {
                float: left;
                margin-bottom: 0
        }
        .dataTables_filter {
                width: 40%;
        }
        .dataTables_length {
                width: auto;
                float: right;
        }
        .dataTables_info {
                clear: none;
                width: auto;
                float: right;
        }
        .div.datatable-paging {
                width: auto;
                float: right;
        }
        .gene_mutation_percent_div {
                display: block;
                float: left;
                background-color: lightgreen;
                height: 12px;
        }
        .mutation_percent_div {
                display: block;
                float: left;
                background-color: green;
                height: 12px;
        }
        .amp_percent_div {
                display: block;
                float: left;
                background-color: red;
                height: 12px;
        }
        .del_percent_div {
                display: block;
                float: left;
                background-color: blue;
                height: 12px;
        }
        .left_float_div {
                display: block;
                float: left;
        }
        .right_float_div {
                display: block;
                float: right;
        }
        .ui-tooltip-wide {
            max-width: 600px;
        }
        .datatable-name {
                float: left;
                font-weight: bold;
                font-size: 120%;
                vertical-align: middle;
        }
        .datatable-show-more {
            float: left;
        }
</style>

<script type="text/javascript" src="js/src/patient-view/genomic-event-observer.js"></script>
<script type="text/javascript">

var print = <%=print%>;
var placeHolder = <%=Boolean.toString(showPlaceHoder)%>;
var mutationProfileId = <%=mutationProfileStableId==null%>?null:'<%=mutationProfileStableId%>';
var cnaProfileId = <%=cnaProfileStableId==null%>?null:'<%=cnaProfileStableId%>';
var mrnaProfileId = <%=mrnaProfileStableId==null%>?null:'<%=mrnaProfileStableId%>';
var hasCnaSegmentData = <%=hasCnaSegmentData%>;
var hasAlleleFrequencyData = <%=hasAlleleFrequencyData%>;
var showGenomicOverview = <%=showGenomicOverview%>;
var caseIdsStr = '<%=caseId%>';
var caseIds = caseIdsStr.split(" ");
var cancerStudyName = "<%=cancerStudy.getName()%>";
var cancerStudyId = '<%=cancerStudy.getCancerStudyStableId()%>';
var genomicEventObs =  new GenomicEventObserver(<%=showMutations%>,<%=showCNA%>, hasCnaSegmentData);
var drugType = drugType?'<%=drugType%>':null;
var clinicalDataMap = <%=jsonClinicalData%>;

var mapCaseColor = {};
var mapCaseLabels = {};
var mapCaseIndices = {};

$(document).ready(function(){
    if (print) $('#page_wrapper_table').css('width', '900px');
    outputClinicalData();
    setUpPatientTabs();
    initTabs();
    var openTab = window.location.hash.substr(1);
    if (openTab) {
        switchToTab(openTab);
    }
});

function setUpPatientTabs() {
    $('#patient-tabs').tabs();
    $('#patient-tabs').show();
    fixCytoscapeWebRedraw();
}

function initTabs() {
    var tabContainers = $('.patient-section');
    tabContainers.hide().filter(':first').show();

    $('.patient-tab').click(function () {
            tabContainers.hide();
            tabContainers.filter(this.hash).show();
            $('.patient-tab').removeClass('selected');
            $(this).addClass('selected');
            return false;
    }).filter(':first').click();   
}

function fixCytoscapeWebRedraw() {
    // to initially hide the network tab
    $("#pathways").attr('style', 'display: none !important; height: 0px; width: 0px; visibility: hidden;');
    
    // to fix problem of flash repainting
    $("a.patient-tab").click(function(){
        if($(this).attr("href")==="#pathways") {
            $("#pathways").removeAttr('style');
        } else {
            $("#pathways").attr('style', 'display: block !important; height: 0px; width: 0px; visibility: hidden;');
        }
    });
}

function switchToTab(toTab) {
    $('.patient-section').hide();
    $('.patient-section#'+toTab).show();
    $('#patient-tabs').tabs("option", "active",$('#patient-tabs ul a[href="#'+toTab+'"]').parent().index());
    if (toTab==='images') {
        loadImages();
    }
}

function getEventString(eventTableData,dataCol,overviewCol) {
    var s = [];
    for (var i=0; i<eventTableData.length; i++) {
        if (overviewCol==null || eventTableData[i][overviewCol])
            s.push(eventTableData[i][dataCol]);
    }
    return s.join(",");
}

function getEventIndexMap(eventTableData,idCol) {
    var m = {};
    for (var i=0; i<eventTableData.length; i++) {
        m[eventTableData[i][idCol]] = i;
    }
    return m;
}
    
function addNoteTooltip(elem, content) {
    $(elem).qtip({
        content: (typeof variable === 'undefined' ? {attr: 'alt'} : content),
        hide: { fixed: true, delay: 100 },
        style: { classes: 'ui-tooltip-light ui-tooltip-rounded' },
        position: {my:'top left',at:'bottom center'}
    });
}

function addMoreClinicalTooltip(elemId, caseId) {
    var clinicalData = [];
    for (var key in clinicalDataMap[caseId]) {
        clinicalData.push([key, clinicalDataMap[caseId][key]]);
    }
    
    if (clinicalData.length===0) {
        $('#'+elemId).remove();
    } else {
        $('#'+elemId).qtip({
            content: {
                text: '<table id="more-clinical-table-'+caseId+'"></table>'
            },
            events: {
                render: function(event, api) {
                    $('#more-clinical-table-'+caseId).dataTable( {
                        "sDom": 't',
                        "bJQueryUI": true,
                        "bDestroy": true,
                        "aaData": clinicalData,
                        "aoColumnDefs":[
                            {
                                "aTargets": [ 0 ],
                                "fnRender": function(obj) {
                                    return '<b>'+obj.aData[ obj.iDataColumn ]+'</b>';
                                }
                            },
                            {
                                "aTargets": [ 1 ],
                                "bSortable": false
                            }
                        ],
                        "aaSorting": [[0,'asc']],
                        "oLanguage": {
                            "sInfo": "&nbsp;&nbsp;(_START_ to _END_ of _TOTAL_)&nbsp;&nbsp;",
                            "sInfoFiltered": "",
                            "sLengthMenu": "Show _MENU_ per page"
                        },
                        "iDisplayLength": -1
                    } );
                }
            },
            hide: { fixed: true, delay: 100 },
            style: { classes: 'ui-tooltip-light ui-tooltip-rounded ui-tooltip-wide' },
            position: {my:'top right',at:'bottom right'}
        });
    }
}

function addDrugsTooltip(elem, my, at) {
    $(elem).each(function(){
        $(this).qtip({
            content: {
                text: '<img src="images/ajax-loader.gif"/>',
                ajax: {
                    url: 'drugs.json',
                    type: 'POST',
                    data: {<%=DrugsJSON.DRUG_IDS%>: $(this).attr('alt')},
                    success: function(drugs,status) {
                        var txt = [];
                        for (var i=0, n=drugs.length; i<n; i++) {
                            var drug = drugs[i];
                            var txtDrug = [];
                            if (drug[2]) {
                                txtDrug.push("Drug name:</b></td><td><b>"+drug[2]+"</b>");
                            }
                            if (drug[1]) {
                                txtDrug.push("Target:</b></td><td><b>"+drug[1]+"</b>");
                            }
                            if (drug[3]) {
                                txtDrug.push("Synonyms:</b></td><td>"+drug[3]);
                            }
                            if (drug[4]) {
                                txtDrug.push("FDA approved?</b></td><td>"+(drug[4]?"Yes":"No"));
                            }
                            if (drug[5]) {
                                txtDrug.push("Description:</b></td><td>"+drug[5]);
                            }
                            if (drug[7]) { // xref
                                var xref = [];
                                var nci = drug[7]['NCI_Drug'];
                                if (nci) xref.push("<a href='http://www.cancer.gov/drugdictionary?CdrID="+nci+"'>NCI</a>");
                                var pharmgkb = drug[7]['PharmGKB'];
                                if (pharmgkb) xref.push("<a href='http://www.pharmgkb.org/views/index.jsp?objId="+pharmgkb+"'>PharmGKB</a>");
                                var drugbank = drug[7]['DrugBank'];
                                if (drugbank) xref.push("<a href='http://www.drugbank.ca/drugs/"+drugbank+"'>DrugBank</a>");
                                var keggdrug = drug[7]['KEGG Drug'];
                                if (keggdrug) xref.push("<a href='http://www.genome.jp/dbget-bin/www_bget?dr:"+keggdrug+"'>KEGG Drug</a>");
                                
                                if (xref.length) {
                                    txtDrug.push("Data sources:</b></td><td>"+xref.join(",&nbsp;"));
                                }
                            }
                            if (drug[8]>0) {
                                var nci = drug[7]['NCI_Drug'];
                                if (nci) {
                                    txtDrug.push("Clinical Trials:</b></td><td><a href='http://www.cancer.gov/Search/ClinicalTrialsLink.aspx?idtype=1&id="+nci+"'>"+drug[8]+" clinical trial"+(drug[8]>1?"s":"")+"</a>");
                                }
                            }
                            txt.push("<table><tr valign='top'><td nowrap='nowrap'><b>"+txtDrug.join("</td></tr><tr valign='top'><td nowrap='nowrap'><b>")+"</td></tr></table>");
                        }
                        var html = txt.join('<hr><br/>');
                        this.set('content.text', html);
                    }
                }
            },
            hide: { fixed: true, delay: 100 },
            style: { classes: 'ui-tooltip-light ui-tooltip-rounded ui-tooltip-wide' },
            position: { my: my, at: at }
        });
    });
}

/**
* modified from http://jsfiddle.net/H2SKt/1/
**/
function d3PieChart(svg, data, radius, colors) {
    var chart = svg
        .data([data])
        .append("g")
        .attr("transform", "translate(" + radius + "," + radius + ")");

    var arc = d3.svg.arc()
        .outerRadius(radius);

    var pie = d3.layout.pie()
        .value(function(d) { return d; })
        .sort(null);

    var arcs = chart.selectAll("g.slice")
        .data(pie) 
        .enter()
        .append("g")
        .attr("class", "slice");

    arcs.append("path")
        .attr("fill", function(d, i) { return colors[i]; } )
        .attr("d", arc);

    return chart;
}

function d3AccBar(svg, data, width, colors) {
    var acc = [];
    var sum = 0;
    for (var i=0; i<data.length; i++) {
        acc.push(sum);
        sum += data[i];
    }
    
    var vd = [];
    for (var i=0; i<data.length; i++) {
        vd.push({
            start: width*acc[i]/sum,
            width: width*data[i]/sum,
            color: colors[i]
        });
    }

    var chart = svg.selectAll(".bar")
        .data(vd) 
        .enter()
        .append("g")
        .attr("class", "bar")
        .attr("transform", function(d,i) { return "translate(" + d.start + "," + 3 + ")"; });

    chart.append("rect")
        .attr("width", function(d, i) { return d.width; })
        .attr("height", 8)
        .attr("fill", function(d, i) { return d.color; } );

    return chart;
}

function d3CircledChar(g,ch,circleColor,textColor) {
    g.append("circle")
        .attr("r",5)
        .attr("stroke",circleColor)
        .attr("fill","none");
    g.append("text")
        .attr("x",-3)
        .attr("y",3)
        .attr("font-size",7)
        .attr("fill",textColor)
        .text(ch);
}
    
function plotMrna(div,alts) {
    $(div).each(function() {
        if (!$(this).is(":empty")) return;
        var gene = $(this).attr("alt");
        var mrna = alts.getValue(gene, 'mrna');
        d3MrnaBar($(this)[0],mrna.perc);
        $(this).qtip({
            content: {text: "mRNA level of the gene in this tumor<br/><b>mRNA z-score</b>: "
                        +mrna.zscore.toFixed(2)+"<br/><b>Percentile</b>: "+mrna.perc+"%"},
            hide: { fixed: true, delay: 10 },
            style: { classes: 'ui-tooltip-light ui-tooltip-rounded' },
            position: {my:'top left',at:'bottom center'}
        });
    });
}

function d3MrnaBar(div,mrnaPerc) {
    var textWidth = 30,
        graphWidth = 30,
        circleR = 3,
        width = graphWidth+textWidth+2*circleR,
        height = 12;

    var svg = d3.select(div).append('svg')
        .attr("width", width)
        .attr("height", height);

    svg.append("text")
        .attr("x", width)
        .attr('y',11)
        .attr("text-anchor", "end")
        .attr('font-size',10)
        .text(mrnaPerc+"%");

    var bar = svg.append("g")
                .attr("transform", "translate(" + circleR + "," + 0 + ")");

    bar.append("line")
        .attr("x1",-circleR)
        .attr("y1",height/2)
        .attr("x2",graphWidth+circleR)
        .attr("y2",height/2)
        .attr("style", "stroke:gray;stroke-width:2");

    bar.append("circle")
        .attr("cx", graphWidth * mrnaPerc/100)
        .attr("cy", height/2)
        .attr("r", circleR)
        .attr("fill", mrnaPerc>75 ? "red" : (mrnaPerc<25?"blue":"gray"));

}

function formatPatientLink(caseId,cancerStudyId,isPatient) {
    return caseId===null?"":'<a title="Go to patient-centric view" href="case.do?cancer_study_id='
            +cancerStudyId+'&'+(isPatient?'patient_id':'case_id')+'='+caseId+'">'+caseId+'</a>';
}

function trimHtml(html) {
    return html.replace(/<[^>]*>/g,"");
}

function idRegEx(ids) {
    return "(^"+ids.join("$)|(^")+"$)";
}

function outputClinicalData() {
    $("#clinical_div").append("<table id='clinical_table' width='100%'></table>");
    var n=caseIds.length;
    
    // set mapCaseColor
    for (var i=0; i<n; i++) {
        var caseId = caseIds[i];
        var clinicalData = clinicalDataMap[caseId];
        var state = guessClinicalData(clinicalData, ["tumor_type"]);
        mapCaseColor[caseId] = getCaseColor(state);
    }
    
    // reorder based on color
    var colors = {black:1, orange:2, red:3};
    caseIds.sort(function(c1, c2){
        var ret = colors[mapCaseColor[c1]]-colors[mapCaseColor[c2]];
        if (ret===0) return c1<c2?-1:1;
        return ret;
    });
    mapCaseIndices = cbio.util.arrayToAssociatedArrayIndices(caseIds);

    // set labels
    var mapColorCases = {};
    caseIds.forEach(function (caseId) {
        var color = mapCaseColor[caseId];
        if (!(color in mapColorCases)) mapColorCases[color] = [];
        mapColorCases[color].push(caseId);
    });
    for (var color in mapColorCases) {
        var cases = mapColorCases[color];
        var len = cases.length;
        if (len===1) {
            mapCaseLabels[cases[0]]='';
        } else {
            for (var i=0; i<len; i++){
                var _case = cases[i];
                mapCaseLabels[_case] = i+1;
            };
        }
    }
        
    // output
    for (var i=0; i<n; i++) {
        var caseId = caseIds[i];
        var clinicalData = clinicalDataMap[caseId];
        
        var row = "<tr><td><b><u>"+formatPatientLink(caseId, cancerStudyId)+"</b></u>&nbsp;</div>";
        if (n===1) {
            var patientInfo = formatPatientInfo(clinicalData);
            row +="&nbsp;"+patientInfo;
        } else {
            row += "<svg width='12' height='12' class='case-label-header' alt='"+caseId+"'></svg>";
            
            var stateInfo = formatStateInfo(clinicalData);
            if (stateInfo) row +="&nbsp;"+stateInfo;
        }
        row += "</td><td align='right'><a href='#' id='more-clinical-a-"+
                    caseId+"'>More about this tumor</a></td></tr>";
        $("#clinical_table").append(row);
        
        if (n===1) {
            var diseaseInfo = formatDiseaseInfo(clinicalData);
            var patientStatus = formatPatientStatus(clinicalData);
            row = "<tr><td>"+diseaseInfo+"</td><td align='right'>"+patientStatus+"</td></tr-->";
            $("#clinical_table").append(row);
        }
        addMoreClinicalTooltip("more-clinical-a-"+caseId, caseId);
    }
    
    if (n>1) {
        plotCaseLabel('.case-label-header');
        $("#clinical_table").append("<tr><td><a href=\"study.do?cancer_study_id="+
                cancerStudyId+"\">"+cancerStudyName+"</a></td><td></td></tr>");
    }
    
    function formatPatientInfo(clinicalData) {
        var patientInfo = [];
        var gender = guessClinicalData(clinicalData, ['gender']);
        if (gender!==null)
            patientInfo.push(gender);
        var age = guessClinicalData(clinicalData, ['age']);
        if (age!==null)
            patientInfo.push(Math.floor(age) + " years old");

        return patientInfo.join(", ");
    }
    
    function formatStateInfo(clinicalData) {
        var ret = null;
        var state = guessClinicalData(clinicalData, ["tumor_type"]);
        if (state!==null) {
            ret = "<font color='"+getCaseColor(state)+"'>"+state+"</font>";

            var stateLower = state.toLowerCase();
            if (stateLower === "metastatic" || stateLower === "metastasis") {
                var loc = guessClinicalData(clinicalData,["tumor location","tumor site","metastasis site"]);
                if (loc!==null) 
                    ret += ", Tumor location: "+loc;
            }
        }
        return ret;
    }

    function formatDiseaseInfo(clinicalData) {
        var diseaseInfo = [];
        diseaseInfo.push("<a href=\"study.do?cancer_study_id="+
                cancerStudyId+"\">"+cancerStudyName+"</a>");

        var stateInfo = formatStateInfo(clinicalData);
        if (stateInfo) diseaseInfo.push(stateInfo);

        var gleason = guessClinicalData(clinicalData,
                        ["gleason score","overall_gleason_score"]);
        var strGleason = null;
        if (gleason!==null) {
            strGleason = "Gleason: "+gleason;
        } 

        var primaryGleason = guessClinicalData(clinicalData, ["primary_gleason_grade"]);
        var secondaryGleason = guessClinicalData(clinicalData, ["secondary_gleason_grade"]);
        if (primaryGleason!==null && secondaryGleason!==null) {
            strGleason += " (" + primaryGleason + "+" + secondaryGleason + ")";
        }
        if (gleason) diseaseInfo.push(strGleason);

        var histology = guessClinicalData(clinicalData,["histology", "histological_type"]);
        if (histology!==null) {
            diseaseInfo.push(histology);
        }

        var stage = guessClinicalData(clinicalData, ["tumor_stage","2009stagegroup","tumorstage"]);
        if (stage!==null && stage.toLowerCase()!=="unknown") {
            diseaseInfo.push(stage); 
        }

        var grade = guessClinicalData(clinicalData,["tumor_grade", "tumorgrade"]);
        if (grade!==null) {
            diseaseInfo.push(grade);
        }

        // TODO: this is a hacky way to include the information in prad_mich
        var etsRafSpink1Status = guessClinicalData(clinicalData,["ets/raf/spink1 status"]);
        if (etsRafSpink1Status!==null) {
            diseaseInfo.push(etsRafSpink1Status);
        }

        // TODO: this is a hacky way to include the information in prad_broad
        var tmprss2ErgFusionStatus = guessClinicalData(clinicalData,["tmprss2-erg fusion status"]);
        if (tmprss2ErgFusionStatus!==null) {
            diseaseInfo.push("TMPRSS2-ERG Fusion: "+tmprss2ErgFusionStatus);
        }

        // TODO: this is a hacky way to include the information in prad_mskcc
        var ergFusion = guessClinicalData(clinicalData, ["erg-fusion acgh"]);
        if (ergFusion!==null) {
            diseaseInfo.push("ERG-fusion aCGH: "+ergFusion);
        }

        // TODO: this is a hacky way to include the serum psa information for prad
        var serumPsa = guessClinicalData(clinicalData, ["serum psa (ng/ml)","serum psa"]);
        if (serumPsa!==null) {
            diseaseInfo.push("Serum PSA: "+serumPsa);
        }

        return diseaseInfo.join(", ")
    }

    function formatPatientStatus(clinicalData) {
        var oss = guessClinicalData(clinicalData, ["overall_survival_status"]);
        var ossLow = oss===null?null:oss.toLowerCase();
        var dfss = guessClinicalData(clinicalData, ["disease-free_survival_status"]);
        var dfssLow = dfss===null?null:dfss.toLowerCase();
        var osm = guessClinicalData(clinicalData, ["overall_survival_months"]);
        var dfsm = guessClinicalData(clinicalData, ["disease-free_survival_months"]);
        var patientStatus = "";
        if (oss!==null && ossLow!=="unknown") {
            patientStatus += "<font color='"
                    + (ossLow==="living"||ossLow==="alive" ? "green":"red")
                    + "'>"
                    + oss
                    + "</font>";
            if (osm!==null) {
                patientStatus += " (" + Math.round(osm) + " months)";
            }
        }
        if (dfss!==null && dfssLow!=="unknown") {
            if (patientStatus) patientStatus += ", ";
            
            patientStatus += "<font color='"
                    + (dfssLow==="DiseaseFree" ? "green":"red")
                    + "'>"
                    + dfss
                    + "</font>";
            if (dfsm!==null) {
                patientStatus += " (" + Math.round(dfsm) + " months)";
            }
        }
        return patientStatus;
    }

    function guessClinicalData(clinicalData, paramNames) {
        for (var i=0, len=paramNames.length; i<len; i++) {
            var data = clinicalData[paramNames[i]];
            if (typeof data !== 'undefined' && data !== null) return data;
        }
        return null;
    }

    function getCaseColor(caseType) {
        if (!caseType) return "black";
        var caseTypeLower = caseType.toLowerCase();
        if (caseTypeLower==="primary") return "black";
        if (caseTypeLower==="metastatic" || caseTypeLower==="metastasis") return "red";
        if (caseTypeLower==="progressed"
                ||caseTypeLower==="locally progressed"
                || caseTypeLower==="local progression") return "orange";
        return "black";
    }
}

function plotCaseLabel(svgEl,onlyIfEmpty) {
    $(svgEl).each(function() {
        if (onlyIfEmpty && !$(this).is(":empty")) return;
        var caseId = $(this).attr('alt');
        
        var svg = d3.select($(this)[0]);
    
        if (caseId) {
            plotCaselabelInSVG(svg, caseId);
        }
    });
}

function plotCaselabelInSVG(svg, caseId) {
    var label = mapCaseLabels[caseId];
    var color = mapCaseColor[caseId];
    var circle = svg.append("g")
        .attr("transform", "translate(6,6)");
    circle.append("circle")
        .attr("r",6)
        .attr("fill",color);
    circle.append("text")
        .attr("x",-3)
        .attr("y",4)
        .attr("font-size",10)
        .attr("fill","white")
        .text(label);
}

</script>

</body>
</html>
