<%
Boolean includeHelpTab = (Boolean)request.getAttribute("include_network_help_tab");
if (includeHelpTab==null) {
    includeHelpTab = Boolean.TRUE;
}
%>

<div id="network_tabs_sbgn" class="hidden-network-ui">
    <ul>
        <li><a href="#genes_tab_sbgn" class="network-tab-ref" title="Genes"><span>Genes</span></a></li>
        <li><a href="#filtering_tab_sbgn" class="network-tab-ref"
               title="Filtering options"><span>Filtering</span></a></li>
	    <li><a href="#element_details_tab_sbgn" class="network-tab-ref"
	           title="Node details"><span>Details</span></a></li>
        <%if(includeHelpTab){%>
        <li><a href="#help_tab" class="network-tab-ref" title="About & Help"><span>Help</span></a></li>
        <%}%>
    </ul>
    <div id="genes_tab_sbgn">
	    <div class="header">
    		<div id="control_area">
    			<table>
    			<tr>
    				<td>
						<button id="filter_genes" class="tabs-button" title="Hide Selected"></button>
					</td>
					<td>
						<button id="crop_genes" class="tabs-button" title="Show Only Selected"></button>
					</td>
					<td>
						<button id="unhide_genes" class="tabs-button" title="Show All"></button>
					</td>
					<td>					
						<input type="text" id="search_box" value=""/>
					</td>
					<td>
						<button id="search_genes" class="tabs-button" title="Search"></button>
					</td>
				</tr>
				</table>
				<table id="network-resubmit-query">
					<tr>
	        			<td>
	        				<label class="button-text">Submit New Query</label>
	        			</td>
	        			<td>
	        				<button id="re-submit_query" class="tabs-button" title="Submit New Query with Genes Selected Below"></button>
	        			</td>
	        		</tr>
        		</table>
			</div>			
		</div>
		<div id="gene_list_area">
		</div>
    </div>

    <div id="filtering_tab_sbgn">
			<label class="heading">Filter by Alteration:</label>
	    	<div id="slider_area">
	    		<div id="weight_slider_area">
		    		<span class="slider-value">
		    			<input id="weight_slider_field" type="text" value="0"/>
		    		</span>
		    		<span class="slider-min"><label>0</label></span>
		    		<span class="slider-max"><label>MAX</label></span>
		    		<div id="weight_slider_bar"></div>
	    		</div>
	    		
	    		<div id="affinity_slider_area" class="hidden-network-ui">
	    			<span class="slider-value">
	    				<input id="affinity_slider_field" type="text" value="0.80"/>
	    			</span>
	    			<span class="slider-min"><label>0</label></span>
		    		<span class="slider-max"><label>1.0</label></span>
		    		<div id="affinity_slider_bar"></div>
	    		</div>
    		</div>

	        <table id="source_filter">
	        	<tr class="source-header">
	        		<td>
						<label class="heading">Filter by Process Source:</label>
	        		</td>
	        	</tr>
	        </table>

		    <div class="footer">
		    	<table>
		    		<tr>
		    			<td>
		    				<label class="button-text">Update</label>
		    			</td>
		    			<td> 
		    				<button id="update_source" class="tabs-button" title="Update"></button>
		    			</td>
		    		</tr>
		    	</table>
			</div>
    </div>

	<div id="element_details_tab_sbgn">
		<div class="error">
			Currently there is no selected node. Please, select a node to see details.
		</div>
		<div class="genomic-profile-content"></div>
		<div class="biogene-content"></div>
		<div class="drug-info-content"></div>
	</div>

    <%if(includeHelpTab){%>
    <div id="help_tab">
        <jsp:include page="network_sbgn_help.jsp"></jsp:include>
    </div>
    <%}%>
</div>

<% /*
<div id="edge_legend" class="hidden-network-ui" title="Interaction Legend">
	<div id="edge_legend_content" class="content ui-widget-content">
		<table id="edge_type_legend">
			<tr class="edge-type-header">
	        	<td>
	        		<strong>Edge Types:</strong>
	        	</td>
	        </tr>
        	<tr class="in-same-component">
        		<td class="label-cell">
        			<div class="type-label">In Same Component</div>
        		</td>
        		<td class="color-cell">
        			<div class="color-bar"></div>
        		</td>
        	</tr>
        	<tr class="reacts-with">
        		<td class="label-cell">
        			<div class="type-label">Reacts With</div>
        		</td>
        		<td class="color-cell">
        			<div class="color-bar"></div>
        		</td>
        	</tr>
        	<tr class="state-change">
        		<td class="label-cell">
        			<div class="type-label">State Change</div>
        		</td>
        		<td class="color-cell">
        			<div class="color-bar"></div>
        		</td>
        	</tr>
        	<tr class="other">
        		<td class="label-cell">
        			<div class="type-label">Other</div>
        		</td>
        		<td class="color-cell">
        			<div class="color-bar"></div>
        		</td>
        	</tr>
        	<tr class="merged-edge">
        		<td class="label-cell">
        			<div class="type-label">Merged (with different types) </div>
        		</td>
        		<td class="color-cell">
        			<div class="color-bar"></div>
        		</td>
        	</tr>
        </table>
	</div>
</div>
*/ %>
