<%@ page import="org.mskcc.cbio.portal.servlet.QueryBuilder" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Set" %>
<%@ page import="org.apache.commons.lang.StringUtils" %>

<%
    String genes4Network = StringUtils.join((List)request.getAttribute(QueryBuilder.GENE_LIST)," ");
    String geneticProfileIds4Network = StringUtils.join(geneticProfileIdSet," ");
    String cancerTypeId4Network = (String)request.getAttribute(QueryBuilder.CANCER_STUDY_ID);
// 	String caseIds4Network = ((String)request.getAttribute(QueryBuilder.CASE_IDS)).
// 			replaceAll("\\s", " ").trim(); // convert white spaces to space (to prevent network tab to crash)
	String caseIdsKey4Network = (String)request.getAttribute(QueryBuilder.CASE_IDS_KEY);
    String caseSetId4Network = (String)request.getAttribute(QueryBuilder.CASE_SET_ID);
    String zScoreThesholdStr4Network = request.getAttribute(QueryBuilder.Z_SCORE_THRESHOLD).toString();
    String useXDebug = request.getParameter("xdebug");
    if (useXDebug==null)
        useXDebug = "0";
    String netSrc = request.getParameter("netsrc");
    if (netSrc==null)
        netSrc = "cgds";
    String netSize = request.getParameter("netsize");
    if (netSize==null)
        netSize = "large";
    String nLinker = request.getParameter("linkers");
    if (nLinker==null)
        nLinker = "50";
    String diffusion = request.getParameter("diffusion");
    if (diffusion==null)
        diffusion = "0";
%>

<link href="css/network/network_ui.css" type="text/css" rel="stylesheet"/>
<link href="css/network/network_ui_sbgn.css" type="text/css" rel="stylesheet"/>

<script type="text/javascript" src="js/lib/json2.js"></script>
<script type="text/javascript" src="js/lib/cytoscape_web/AC_OETags.min.js"></script>
<script type="text/javascript" src="js/lib/cytoscape_web/cytoscapeweb.min.js"></script>
<script type="text/javascript" src="js/lib/cytoscape_web/cytoscapewebSBGN.min.js"></script>

<!-- <script type="text/javascript" src="js/src/network/network-ui.js"></script> -->
<script type="text/javascript" src="js/src/network/utility-functions.js"></script>
<script type="text/javascript" src="js/src/network/common-functions.js"></script>
<script type="text/javascript" src="js/src/network/network-visualization.js"></script>
<script type="text/javascript" src="js/src/network/network-sbgn-vis.js"></script>
<script type="text/javascript" src="js/src/network/network-viz.js"></script>

<script type="text/javascript">
			// Send genomic data query again
		    var geneDataQuery = {
		        genes: genes,
		        samples: samples,
		        geneticProfileIds: geneticProfiles,
		        z_score_threshold: <%=zScoreThreshold%>,
		        rppa_score_threshold: <%=rppaScoreThreshold%>
		    };

            // show messages in graphml
            function showNetworkMessage(graphml, divNetMsg) {
                var msgbegin = "<!--messages begin:";
                var ix1 = graphml.indexOf(msgbegin);
                if (ix1==-1) {
                    $(divNetMsg).hide();
                } else {
                    ix1 += msgbegin.length;
                    var ix2 = graphml.indexOf("messages end-->",ix1);
                    var msgs = $.trim(graphml.substring(ix1,ix2));
                    if (msgs) {
                        $(divNetMsg).append(msgs.replace(/\n/g,"<br/>\n"));
                    }
                }    
            }
            
            function showXDebug(graphml) {
                if (<%=useXDebug%>) {
                    var xdebugsbegin = "<!--xdebug messages begin:";
                    var ix1 = xdebugsbegin.length+graphml.indexOf(xdebugsbegin);
                    var ix2 = graphml.indexOf("xdebug messages end-->",ix1);
                    var xdebugmsgs = $.trim(graphml.substring(ix1,ix2));
                    $("#cytoscapeweb").css('height','70%');
                    $("#vis_content").append("\n<div id='network_xdebug'>"
                        +xdebugmsgs.replace(/\n/g,"<br/>\n")+"</div>");
                }
            }
            
            window.onload = function() {
                var networkParams = {<%=QueryBuilder.GENE_LIST%>:'<%=genes4Network%>',
                     <%=QueryBuilder.GENETIC_PROFILE_IDS%>:'<%=geneticProfileIds4Network%>',
                     <%=QueryBuilder.CANCER_STUDY_ID%>:'<%=cancerTypeId4Network%>',
                     <%=QueryBuilder.CASE_IDS_KEY%>:'<%=caseIdsKey4Network%>',
                     <%=QueryBuilder.CASE_SET_ID%>:'<%=caseSetId4Network%>',
                     <%=QueryBuilder.Z_SCORE_THRESHOLD%>:'<%=zScoreThesholdStr4Network%>',
                     heat_map:$("#heat_map").html(),
                     xdebug:'<%=useXDebug%>',
                     netsrc:'<%=netSrc%>',
                     linkers:'<%=nLinker%>',
                     netsize:'<%=netSize%>',
                     diffusion:'<%=diffusion%>'
                    };
                // get the graphml data from the server
                $.post("network.do", 
                    networkParams,
                    function(graphml){
                        if (typeof graphml !== "string") {
                            if (window.ActiveXObject) { // IE 
                                    graphml = (new XMLSerializer()).serializeToString(graphml); 
                            } else { // Other browsers 
                                    graphml = (new XMLSerializer()).serializeToString(graphml); 
                            } 
                        }
                        send2cytoscapeweb(graphml, "cytoscapeweb", "network");
                        showXDebug(graphml);
                        showNetworkMessage(graphml, "#network #netmsg");
                    }
                );

                // TODO get the SBGN-ML data from pathway commons and pass it to cytoscapeweb
	            $.post("networkSbgn.do",
	                   networkParams,
	                   function(graphData){
                           // All genes coming from SBGN view are in graphData.sbgn
                           // All attributes can be accessed via: graphData.attributes[rdfid]
                           // Corresponding BioPAX IDs can be accessed via graphData.sbgn2BPMap[sbgnID]
		                   send2cytoscapewebSbgn(graphData, "cytoscapeweb_sbgn", "network_sbgn", geneDataQuery);
		                   // TODO these methods do not work with sbgnml
		                   //showXDebug(sbgnml);
		                   //showNetworkMessage(sbgnml, "#network_sbgn #netmsg");
	                   }
	            );
            }
        </script>

<jsp:include page="network_views.jsp"/>
<jsp:include page="network_div.jsp"/>
<jsp:include page="network_div_sbgn.jsp"/>
