/**
 * PDB Panel View.
 *
 * This view is designed to function in parallel with the 3D visualizer.
 *
 * options: {el: [target container],
 *           model: {geneSymbol: hugo gene symbol,
 *                   pdbColl: collection of PdbModel instances},
 *           mut3dVisView: [optional] reference to the Mutation3dVisView instance,
 *           diagram: [optional] reference to the MutationDiagram instance
 *          }
 */
var PdbPanelView = Backbone.View.extend({
	render: function()
	{
		var self = this;

		// compile the template using underscore
		var template = _.template(
				$("#pdb_panel_view_template").html(),
				{geneSymbol: self.model.geneSymbol});

		// load the compiled HTML into the Backbone "el"
		self.$el.html(template);

		// init pdb panel
		self.pdbPanel = self._initPdbPanel();

		// format after rendering
		self.format();
	},
	format: function()
	{
		var self = this;

		// hide view initially
		self.hideView();

		// format panel controls

		var expandButton = self.$el.find(".expand-collapse-pdb-panel");

		// hide expand button if there is no more chain to show
		if (!self.pdbPanel.hasMoreChains())
		{
			expandButton.hide();
		}
		else
		{
			expandButton.button({
				icons: {primary: "ui-icon-triangle-2-n-s"},
				text: false});
			expandButton.css({width: "300px", height: "12px"});

			expandButton.click(function() {
				self.pdbPanel.toggleHeight();
			});
		}
	},
	hideView: function()
	{
		var self = this;
		self.$el.hide();
	},
	showView: function()
	{
		var self = this;
		self.$el.show();
	},
	/**
	 * Loads the 3D visualizer for the default pdb and chain.
	 * Default chain is one of the chains in the first row.
	 */
	loadDefaultChain: function()
	{
		var self = this;

		var panel = self.pdbPanel;
		var gene = self.model.geneSymbol;
		var vis = self.options.mut3dVisView;

		var gChain = panel.getDefaultChainGroup();
		var defaultDatum = gChain.datum();

		// highlight the default chain
		panel.highlight(gChain);

		// update the color mapper for the 3D visualizer
		// TODO this is not an ideal solution, but...
		// ...while we have multiple diagrams, the 3d visualizer is a singleton
		var colorMapper = function(mutationId, pdbId, chain) {
			var mutationDiagram = self.options.diagram;
			var color = mutationDiagram.mutationColorMap[mutationId];

			if (color)
			{
				// this is for Jmol compatibility
				// (colors should start with an "x" instead of "#")
				color = color.replace("#", "x");
			}

			return color;
		};

		vis.options.mut3dVis.updateOptions({mutationColor: colorMapper});

		// update the view with default chain
		vis.updateView(gene, defaultDatum.pdbId, defaultDatum.chain);
	},
	/**
	 * Initializes the PDB chain panel.
	 *
	 * @return {MutationPdbPanel}   panel instance
	 */
	_initPdbPanel: function()
	{
		var self = this;
		var panel = null;

		var gene = self.model.geneSymbol;
		var pdbColl = self.model.pdbColl;
		var mutationDiagram = self.options.diagram;
		var vis = self.options.mut3dVisView;

		if (mutationDiagram != null)
		{
			var xScale = mutationDiagram.xScale;

			// set margin same as the diagram margin for correct alignment with x-axis
			var options = {el: "#mutation_pdb_panel_" + gene.toUpperCase(),
				marginLeft: mutationDiagram.options.marginLeft,
				marginRight: mutationDiagram.options.marginRight};

			// init panel
			panel = new MutationPdbPanel(options, pdbColl, xScale);
			panel.init();

			// add event listeners for chain selection
			if (vis != null)
			{
				panel.addListener(".pdb-chain-group", "click", function(datum, index) {
					// update view with the selected chain data
					vis.updateView(gene, datum.pdbId, datum.chain);
					// also highlight the selected chain on the pdb panel
					panel.highlight(d3.select(this));
				});
			}
		}

		return panel;
	}
});
