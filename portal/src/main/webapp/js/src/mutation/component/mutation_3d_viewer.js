/**
 * 3D Mutation Visualizer, currently based on Jmol applet.
 *
 * @param name      name of the visualizer (applet/application name)
 * @param options   visualization (Jmol) options
 * @constructor
 */
var Mutation3dVis = function(name, options)
{
	// main container -- html element
	var _container = null;

	// wrapper, created by the Jmol lib -- html element
	var _wrapper = null;

	// Jmol applet reference
	var _applet = null;

	// current selection (mutation positions on the protein)
	var _selection = null;

	// current chain (PdbChainModel instance)
	var _chain = null;

	// spin indicator (initially off)
	var _spin = "OFF";

	// selected style (default: cartoon)
	var _style = "cartoon";

	// default visualization options
	var defaultOpts = {
		// applet/application (Jmol) options
		appOptions: {
			width: 400,
			height: 300,
			debug: false,
			color: "white",
			//use: "HTML5",
			//j2sPath: "js/jsmol/j2s",
			//script: "load ="+pdbid+";",
			//defaultModel: "$dopamine",
			jarPath: "js/lib/jmol/",
			jarFile: "JmolAppletSigned.jar",
			disableJ2SLoadMonitor: true,
			disableInitialConsole: true
		},
		defaultColor: "xDDDDDD", // default color of ribbons
		translucency: 5, // translucency (opacity) of the default color
		chainColor: "x888888", // color of the selected chain
		mutationColor: "xFF0000", // color of the selected mutations
		containerPadding: 10 // padding for the vis container (this is to prevent overlapping)
	};

	// Predefined style scripts for Jmol
	var styleScripts = {
		ballAndStick: "wireframe ONLY; wireframe 0.15; spacefill 20%;",
		ribbon: "ribbon ONLY;",
		cartoon: "cartoon ONLY;"
	};

	var _options = jQuery.extend(true, {}, defaultOpts, options);

	/**
	 * Initializes the visualizer.
	 */
	function init()
	{
		// init applet
		_applet = Jmol.getApplet(name, _options.appOptions);

		// update wrapper reference
		// TODO the wrapper id depends on the JMol implementation
		_wrapper = $("#" + name + "_appletinfotablediv");
		_wrapper.hide();
	}

	/**
	 * Updates visualizer container.
	 *
	 * @param container html element
	 */
	function updateContainer(container)
	{
		// update reference
		_container = $(container);

		var appContainer = _container.find("#mutation_3d_visualizer");

		// set width
		appContainer.css("width", _options.appOptions.width);
		// set height (should be slightly bigger than the app height)
		appContainer.css("height", _options.appOptions.height + _options.containerPadding);
		// move visualizer into its new container
		appContainer.append(_wrapper);
	}

	/**
	 * Toggles the spin.
	 */
	function toggleSpin()
	{
		_spin == "ON" ? _spin = "OFF" : _spin = "ON";

		var script = "spin " + _spin + ";";

		Jmol.script(_applet, script);
	}

	/**
	 * Changes the style of the visualizer.
	 *
	 * @param style name of the style
	 */
	function changeStyle(style)
	{
		// update selected style
		_style = style;

		var script = "select all;" +
		             styleScripts[style];

		Jmol.script(_applet, script);
	}

	/**
	 * Shows the visualizer panel.
	 */
	function show()
	{
		if (_wrapper != null)
		{
			_wrapper.show();
		}

		if (_container != null)
		{
			_container.show();
		}
	}

	/**
	 * Hides the visualizer panel.
	 */
	function hide()
	{
		if (_wrapper != null)
		{
			_wrapper.hide();
		}

		if (_container != null)
		{
			_container.hide();
		}
	}

	function isVisible()
	{
		return !(_container.is(":hidden"));
	}

	/**
	 * Reloads the protein view for the given PDB id
	 * and the chain.
	 *
	 * @param pdbId   PDB id
	 * @param chain   PdbChainModel instance
	 */
	function reload(pdbId, chain)
	{
		// TODO pdbId and/or chainId may be null

		// load the corresponding pdb
		Jmol.script(_applet, "load=" + pdbId);

		var selection = [];

		// TODO focus on the current segment instead of the chain?

		// highlight the positions (residues)
		for (var mutationId in chain.positionMap)
		{
			var position = chain.positionMap[mutationId];

			// TODO remove duplicates from the array (use another data structure such as a map)
			selection.push(generateScriptPos(position) + ":" + chain.chainId);
		}

		// save current chain & selection for a possible future restore
		_selection = selection;
		_chain = chain;

		// if no positions to select, then select "none"
		if (selection.length == 0)
		{
			selection.push("none");
		}

		// construct Jmol script string
		var script = "select all;" + // select everything
		             styleScripts[_style] + // show selected style view
		             "color [" + _options.defaultColor + "] " + // set default color
		             "translucent [" + _options.translucency + "];" + // set default opacity
		             "select :" + chain.chainId + ";" + // select the chain
		             "color [" + _options.chainColor + "];" + // set chain color
		             "select " + selection.join(", ") + ";" + // select positions (mutations)
		             "color red;" + // highlight selected area
		             "spin " + _spin; // set spin

		// run script
		Jmol.script(_applet, script);
	}

	function focus(pileup)
	{
		// no chain selected yet, terminate
		if (!_chain)
		{
			return;
		}

		// assuming all other mutations in the same pileup have
		// the same (or very close) mutation position.
		var id = pileup.mutations[0].mutationId;

		var position = _chain.positionMap[id];

		if (position)
		{
			// TODO center and zoom to the selection
			var script = "select " + generateScriptPos(position) + ":" + _chain.chainId + ";";

			//Jmol.script(_applet, script);
		}
	}

	/**
	 * Generates a position string for Jmol scripting.
	 *
	 * @position object containing PDB position info
	 * @return {string} position string for Jmol
	 */
	function generateScriptPos(position)
	{
		var posStr =position.start.pdbPos;

		if (position.end.pdbPos > position.start.pdbPos)
		{
			posStr += "-" + position.end.pdbPos;
		}

		return posStr;
	}

	// return public functions
	return {init: init,
		show: show,
		hide: hide,
		isVisible: isVisible,
		reload: reload,
		focusOn: focus,
		updateContainer: updateContainer,
		toggleSpin: toggleSpin,
		changeStyle : changeStyle};
};
