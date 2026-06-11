

//******************************************************************************
//** Mapper: Flexible map creation                                            **
Class "Mapper" (CallingDbox)                                                //** StartClass
// Properties:
// ********************************************************
//
//   -- These properties can be set control map features --
//   -- and should be set prior to calling .Create()     --
//   ------------------------------------------------------
//  .Files.Zones = TAZ layer filename (optional)
//  .MapName = Name of map (defaults to "Map")
//  .Scope = Initial map scope (defaults to network scope)
//
//   -- These properties are set as defaults in the init --
//   -- step and tend to vary by model. They can be      --
//   -- overridden after the mapper object is created    --
//   ------------------------------------------------------
//  .Queries.Centroids = Selection query to identify centroid connectors
//  .Queries.HideLinks = Selection query to hide links
//  .Settings.Network.FT
//     .[FT Name] = {int index, int width, string color, string style)
//       - [FT Name] = Descriptive facility type name
//       - index = FT link value
//       - style and color must be available in the Mapper style and color list
//
//   -- These properties are set by methods and should be --
//   -- treated as or read-only                           --
//   -------------------------------------------------------
//  .Files.Network = Network filename
//  .Map = Map handle
//  .Layers = Layers avaialble in the map:
//      .Links = Network link layer
//      .Nodes = Network node layer
//      .Zones = Zone layer
//  .Views = Views avaialble
//      .Flow = Flow view (assignment results)
//      .NetFlow = Network layer joined to the flow view
//      .CompareFlow = Flow view for comparison
//      .NetCompareFlow = Networ+Flow+CompareFlow
//
// Methods
// *********************************************************
//  .Create(base_file, StopRedraw) -> Create a new map
//      base_file = String base layer filename (should be a line layer or
//                  a route system)
//      Boolean StopRedraw = True to supress map redraw, False (default) to 
//                           leave mapredraw on
//  .Connectors(qry, Visible) -> Selects centroid connectors
//      qry = Centroid connector selection set query
//      Visible = True/False: show centroid connectors if True
//  .HideLinks(qry, Invisible) -> Selects links that can be hidden
//      qry = Links to hide selection set query
//      Visible = True/False: hide links if false
//
//  .JoinFlows(FlowFile) -> Join assignment results to the network
//      FlowFile = Assignment result filename
//
//  .JoinCompareFlows(FlowFile) -> Join a "baseline" flow file to the network 
//                                 for comparison to the already joined flow
//                                 file and compute difference expressions.
//      FlowFile = Assignment result filename for comparison
//
//  .Label(expr, Opts) -> Apply labels to the link layer
//      expr = Label expression
//      Opts. (All are optional)
//          .Font = Label Font (See SetLabels() for details)
//          .Color = Label color
//          .CCFont = Font for centroid connector labels
//          .CCColor = Color for centroid connector labels
//
//  .ClearThemes(lyr) -> Clear all themes from the layer
//    string lyr = layer name
//  .Bandwidths(Field, Opts) -> Add a bandwidth theme to the link layer
//      Field = Name of field to control bandwidth theme
//      Opts. (All are optional)
//          .[Data Source] = "Screen" to set sizes based on on-screen values or
//                           "All" (default) to use all values on the network
//          .[Line Style] = Line style to use for theme - only used for an AB/BA 
//                          theme, defaulting to "Double"
//
//  .LOS(Field) --> Add an LOS color theme to the map
//      Field = Field containing LOS values
//
//  .Redraw() -> Redraw the map and update the map toolbar
//
//  .SetDataYear(mdb_file) --> Allow the user to select a data year.  Set the
//                             value in the database file.

    //Initialize:
    // - Check for network existence
    // - Set up default map properties
    init do
    NextStep= "Init"
    
        shared UT
        self.UT <= UT //weak reference to avoid memory locking theUT object
    
        //Default settings 
        self.MapName = "Map"
        self.Files.Network = null
        //self.Files.Routes = null
        self.Files.Zones = null
        self.Scope = null //defaults to network scope
        
        //Default Network Styles
        self.Settings.Network.FTFormula = "if Left(NFC_FLAG,1) = 'R' then 11 else if NFC_FLAG = 'FCD' then 12 else NFC"
        self.Settings.Network.FTField = "FT"
        self.Settings.Network.CCValue = 99
        self.Settings.Network.FT.[Interstate Freeway] = {1, 2.5, "Black", "Solid"}
        self.Settings.Network.FT.[Other Freeway] = {2, 2.5, "DkGray", "Solid"}
        self.Settings.Network.FT.[Principal Arterial] = {3, 2, "Red", "Solid"}
        self.Settings.Network.FT.[Minor Arterial] = {4, 1.5, "Green", "Solid"}
        self.Settings.Network.FT.[Major Collector] = {5, 1, "Blue", "Solid"}
        self.Settings.Network.FT.[Minor Collector] = {6, 1, "LtBlue", "Solid"}
        self.Settings.Network.FT.[Local Road] = {7, 1, "Gray", "Solid"}   
        self.Settings.Network.FT.[Uncertified Road] = {9, 1, "Gray", "Solid"}   
        
        self.Settings.Network.FT.[Ramp] = {11, 1, "Black", "Solid"}   
        self.Settings.Network.FT.[Collector Distributor] = {12, 1.5, "Black", "Solid"}   
        
        self.Settings.Network.FT.[External Connector] = {50, 0, "Gray", "Dash"}
        self.Settings.Network.FT.[Centroid Connector] = {99, 0, "Gray", "Dash"}
        
        self.Settings.Network.FT.[Transit DPM] = {81, 0, "Orange", "Solid"}
        self.Settings.Network.FT.[Transit AADD] = {82, 0, "Orange", "Solid"}
        self.Settings.Network.FT.[Transit WALLY] = {83, 0, "Orange", "Solid"}
        self.Settings.Network.FT.[Transit DTOGS] = {84, 0, "Orange", "Solid"}
        
		self.Settings.Network.FT.[Walk Connector] = {96, 0, "Orange", "Dash"}
        
        self.Periods = {"DY", "EA", "AM", "MD", "PM", "EV"}
        
        
        //Default map scope
        self.Scope = Scope(Coord(-83291620, 42450366), 91.939911, 102.468316, 0)
        //Use the following to change:
        /*
        scp = GetMapWindowScope()
        line = "Scope(Coord(" + 
            string(scp.center.lon) + ", " + string(scp.center.lat) + "), " + 
            string(scp.width) + ", " + string(scp.height) + ", 0)"
        CopyToClipboard({{"Text", line}})
        
        */
        
        //Expressions
        self.count_field = "MAP_COUNT" //!!! Non-standard, using MAP_Count instead of VAL_Count
                                       //    This can be set from outside to summarize a different period
        
        //Map info for dbox
        //List of map names (indexed by radio button type)
        TrafficMap = null
        TrafficMap.MapNames = {"Validation Map",          //1
                               "Volume Map",              //2
                               "LOS Map",                 //3
                               "Select Link/Node Map",    //4
                               "Traffic Comparison Map",  //5
                               "VC Map"}                  //6

        //List of available settings checkboxes
        //The update macro enables all of these checkboxes unless listed in
        //TrafficMap.Disable (in which case the checkbox is disabled)
        TrafficMap.Settings = {"NCHRP", "Thousands", "Volumes", "Highlight", "Connectors", "Big Labels", 
                               "Label Connectors", "Period"}
        
        //List of settings to disable for each map.  If present in this array, 
        //  settings buttons will be disabled and set to the specified value.
        //  Specified value cannot be null (but can be 0)
        TrafficMap.Disable.[Validation Map].NCHRP = 0
        TrafficMap.Disable.[Validation Map].Volumes = 1
        
        TrafficMap.Disable.[Volume Map].Volumes = 1
        TrafficMap.Disable.[Volume Map].Highlight = 0
        
        TrafficMap.Disable.[LOS Map].Highlight = 0
        TrafficMap.Disable.[LOS Map].Period = 1
        
        TrafficMap.Disable.[Select Link/Node Map].NCHRP = 0
        TrafficMap.Disable.[Select Link/Node Map].Highlight = 0
        
        TrafficMap.Disable.[Traffic Comparison Map].NCHRP = 0
        TrafficMap.Disable.[Traffic Comparison Map].Highlight = 0
        //TrafficMap.Disable.[Traffic Comparison Map].Period = 1
        
        TrafficMap.Disable.[VC Map].Highlight = 0
                     
        //Default map type and options
        TrafficMap.Type = 2
        TrafficMap.Opts.NCHRP = 0
        TrafficMap.Opts.Thousands = 1
        TrafficMap.Opts.Volumes = 0
        TrafficMap.Opts.Connectors = 1
		TrafficMap.Opts.[Big Labels] = 1
        TrafficMap.Opts.Highlight = 1
        TrafficMap.Opts.[Label Connectors] = 1
		TrafficMap.Opts.[Input Network] = 0
        TrafficMap.Opts.Period = 1

        //Saved options (default to the same as original, )
        Self.TrafficMap = TrafficMap
        Self.TrafficMap.Save = CopyArray(Self.TrafficMap.Opts)

        //Label format settings
        Self.fmt_list = {"12 (Thousands)", "12.0 (Thousands)", "12,345"} //Description in GUI
        Self.fmt_strings = {"*.", "*.0", "*,."}  //Format string
        Self.fmt_units = {1000, 1000, 1}  //Divide by value
		
		//Separate SelectMap Options (just need to set defaults)
        SelectMap = null
        SelectMap.Type = 1
        SelectMap.Opts.Period = 1
        SelectMap.Opts.Connectors = 1
        SelectMap.Opts.Labels = 1
        SelectMap.Opts.Locals = 1
		SelectMap.Opts.SelVal = 1
		
		Self.SelectMap = SelectMap
        Self.SelectMap.Save = CopyArray(Self.SelectMap.Opts)
        
    enditem
    //EndMethod

    //Set scenario-specific variables
    Macro "SetScenario" (Args) do
	shared UT
    
        //Identify network and rts files
        taz_file = Args.TAZ
		self.[DBD File] = Args.[Highway DB]
        
        //List of periods and corresponding flow files
        flow_template = Args.[Highway Flows]
        flow_list = {Substitute(flow_template, "%PER_HWY%", "DY", )}
        flow_list = flow_list + self.UT.Expand(flow_template)        
        self.FlowList = flow_list
        
        //Select Zone OD files by period
		z = SplitPath(Args.SelectMatrix)
		selod_tempate = z[1] + z[2] + "SelectSummary_%PER_HWY%.bin"
        selod_list = {Substitute(selod_tempate, "%PER_HWY%", "DY", )}
        selod_list = selod_list + self.UT.Expand(selod_tempate)
        self.SelectODList = selod_list
		
		//Identify selection queries
        if GetFileInfo(Args.[Crit_Query]) != null then do
            sellist = UT.SelectList(Args.[Crit_Query])
            self.SelList = sellist
        end else do
            self.SelList = null
        end
        
    enditem
    //EndMethod
    
    //Create a new map
    Macro "Create" (base_file, StopRedraw) do
    
        if base_file = null or TypeOf(base_file) != 'string' then 
            Throw("Cannot create map: No base layer filename provided")
        if GetFileInfo(base_file) = null then
            Throw(self.UT.StrCombine("Cannot create map. File not found:\n%1%", {base_file}))
        
        t = SplitPath(base_file)
        base_ext = Lower(t[4])
        
        if base_ext != '.rts' and base_ext != '.dbd' then 
            Throw(self.UT.StrCombine("Cannot create map: Base layer must be a " + 
                                "geographic file or route system file.\n%1%", 
                                {base_file}))
    
        //Get route system line layer
        if base_ext = '.rts' then do
            self.Files.Routes = base_file
            t = GetRouteSystemInfo(base_file)
            self.Files.Network = t[1]
            t = t[3] //info Opts
            self.Layers.Routes = t.Name  //Rts layer name in file
            t = null
        end
        else
            self.Files.Network = base_file
    
        //Use default scope if not defined externally
        if self.Scope = null then do
            t = GetDBInfo(self.Files.Network)
            self.Scope = t[1]
            t = null
        end
        
        //Create map
        Opts = null
        Opts.Scope = self.Scope
        self.Map = CreateMap(self.MapName, Opts)
        if StopRedraw then SetMapRedraw(self.Map, "False")
        
        //Zones
        if self.Files.Zones != null and 
           GetFileInfo(self.Files.Zones) != null then do
            {zone_lyr} = GetDBLayers(self.Files.Zones)
            self.Layers.Zones = AddLayer(self.Map, zone_lyr, 
                                         self.Files.Zones, zone_lyr)
            RunMacro("G30 new layer default settings", self.Layers.Zones)
            taz_color = self.Colors("LtOrange")
			SetLayer(self.Layers.Zones)
			SelectNone("Selection")
            SetLineColor(self.Layers.Zones+"|", taz_color)
            SetLineWidth(self.Layers.Zones+"|", 3.5)
        end
        
        //Routes
        if base_ext = '.rts' then do
            lyrs = AddRouteSystemLayer(self.Map, self.Layers.Routes, 
                                       self.Files.Routes,)
            RunMacro("Set Default RS Style", lyrs, "TRUE", "TRUE")
            self.Layers.Routes = lyrs[1]
            self.Layers.Stops  = lyrs[2]
            //Not using physical stops
            self.Layers.Nodes = lyrs[4]
            self.Layers.Links = lyrs[5]
            lyrs = null
			
        end
        //Network
        else do
            {node_lyr, link_lyr} = GetDBLayers(self.Files.Network)
            self.Layers.Nodes = AddLayer(self.Map, node_lyr, 
                                         self.Files.Network, node_lyr)
            self.Layers.Links = AddLayer(self.Map, link_lyr, 
                                         self.Files.Network, link_lyr)
                                         
        end
        //Network layer settings
        RunMacro("G30 new layer default settings", self.Layers.Nodes)
        SetLayerVisibility(self.Map+"|"+self.Layers.Nodes, "False")

        RunMacro("G30 new layer default settings", self.Layers.Links)
        
        SetLayer(self.Layers.Nodes)
        SelectNone("Selection")
        SetLayer(self.Layers.Links)
        SelectNone("Selection")
        
        //Set line style to default TransCAD gray
        SetArrowheads(self.Layers.Links+"|", "None")
        SetLineStyle(self.Layers.Links+"|", self.Styles("Solid"))
        SetLineColor(self.Layers.Links+"|", self.Colors("Gray"))
        SetLineWidth(self.Layers.Links+"|", 0)
        
        //FT Expression
        if self.Settings.Network.FTFormula != null then do
            CreateExpression(self.Layers.Links, self.Settings.Network.FTField, self.Settings.Network.FTFormula, )
        end

    enditem
    //EndMethod
	
	Macro "JoinSelectFlows" (flow_files, per_list, sel_list)do
    
        SetVs = null
        FldSpec = {{"ID1", "Integer", 10, 0, "True"}}
        for _per = 1 to per_list.length do
            per = per_list[_per]
            join_vw = self.JoinFlows(flow_files[_per])
            if _per = 1 then do
                SetVs.ID1 = GetDataVector(join_vw+"|", "ID", )
            end
            
            //Getlist of fields to read, including total flows
            flds = {"AB_Flow", "BA_Flow", "Tot_Flow"}
            for sel in sel_list do
                flds = flds + {'AB_Flow_'+sel, 'BA_Flow_'+sel}
            end
            
            //Arrange data for writing and create field specs for table creation
            Vs = GetDataVectors(join_vw+"|", flds, )
            for ii = 1 to flds.length do
                FldSpec = FldSpec + {{flds[ii]+"_"+per, "Real", 10, 2}}
                SetVs.(flds[ii]+"_"+per) = Vs[ii]
            end
            
            //Close the joined view, unless is is in use by another map
            on error goto NoCloseJoin
            CloseView(join_vw)
            NoCloseJoin:
            self.Views.NetFlow = null
            
        end
        
        //Create a memory view with all this info
        sel_mem = CreateTable("SelectFlowsMem", , "MEM", FldSpec)
        AddRecords(sel_mem, , , {{"Empty Records", SetVs.ID1.length}})
        SetDataVectors(sel_mem+"|", SetVs, )
        self.Views.SelectFlows = JoinViews("SelectFlows", self.Layers.Links+".ID", sel_mem+".ID1", )
        CloseView(sel_mem)
        
        Return(MP.Views.SelectFlows)
    
    enditem //EndMethod
    
	Macro "JoinSelectOD" (selod_files, per_list, sel_list)do
    
        SetVs = null
        FldSpec = {{"TAZ", "Integer", 10, 0, "True"}}
        for _per = 1 to per_list.length do
            per = per_list[_per]
            join_vw = self.JoinData(selod_files[_per], "TAZ")
            if _per = 1 then do
                SetVs.TAZ = GetDataVector(join_vw+"|", "ID", ) //ID contains the TAZ number, and is unique on the TAZ layer only
            end
            
            //Getlist of fields to read, including total flows
            flds = null
            for sel in sel_list do
                flds = flds + {sel+'_Origins', sel+'_Destinations'}
            end
            
            //Arrange data for writing and create field specs for table creation
            Vs = GetDataVectors(join_vw+"|", flds, )
            for ii = 1 to flds.length do
                FldSpec = FldSpec + {{flds[ii]+"_"+per, "Real", 10, 2}}
                SetVs.(flds[ii]+"_"+per) = Vs[ii]
            end
            
            //Close the joined view, unless is is in use by another map
            on error goto NoCloseDataJoin
            CloseView(join_vw)
            NoCloseDataJoin:
            self.Views.ZoneData = null
            
        end
        
        //Create a memory view with all this info
        sel_mem = CreateTable("SelectODMem", , "MEM", FldSpec)
        AddRecords(sel_mem, , , {{"Empty Records", SetVs.TAZ.length}})
        SetDataVectors(sel_mem+"|", SetVs, )
        self.Views.SelectOD = JoinViews("SelectOD", self.Layers.Zones+".ID", sel_mem+".TAZ", )
        CloseView(sel_mem)
        
        Return(self.Views.SelectOD)
    
    enditem //EndMethod
    
    //Create a centroid connector selection set
    Macro "Connectors" (qry, Visible) do
	
		if self.Settings.Network.FTField != "FT" then do
			qry = Substitute(qry, "FT", self.Settings.Network.FTField, )
		end
        qry = "Select * Where " + self.Settings.Network.FTField + " = " + String(self.Settings.Network.CCValue)
    
        SetLayer(self.Layers.Links)
        CentroidCount = SelectByQuery("CentroidConnectors", "Several", qry, )
        if CentroidCount > 0 then do
            if Visible then 
                SetDisplayStatus(self.Layers.Links+"|CentroidConnectors", "Active")
            else
                SetDisplayStatus(self.Layers.Links+"|CentroidConnectors", "Invisible")
        end
    
    enditem
    //EndMethod
    
    //Create Hide Links (links that doesn't need to be shown) selection set
    Macro "HideLinks" (qry, Invisible) do
	
		if self.Settings.Network.FTField != "FT" then do
			qry = Substitute(qry, "FT", self.Settings.Network.FTField, )
		end
    
        //If the hide links query is null, then no selection set will be 
        //created
        if qry != null then do
            SetLayer(self.Layers.Links)
            cnt = SelectByQuery("HideLinks", "Several", qry, )
            if cnt > 0 then do
                if Visible then 
                    SetDisplayStatus(self.Layers.Links+"|HideLinks", "Active")
                else
                    SetDisplayStatus(self.Layers.Links+"|HideLinks", "Invisible")
            end
        end
    
    enditem
    //EndMethod

    Macro "ReduceLabels" (qry_list, include_flag) do
    
        
        //Select items to have the reduced labels
        lyr = GetLayer()
        cnt = 0
        SetLayer(self.Layers.Links)
        SelectNone("ReducedLabels")
        for ii = 1 to qry_list.length do
            if !include_flag[ii] then do
                cnt = cnt + SelectByQuery("ReducedLabels", "More", "Select * Where " + qry_list[ii][2], )
            end
        end
        SetDisplayStatus(self.Layers.Links+"|ReducedLabels", "Active")
        SetLayer(lyr)
        
        if cnt = 0 then do
            DeleteSet("ReducedLabels")
        end else do
        //Change the label style for this set
            lbl = self.LinkLabelExp
            Opts = null
            Opts.[Priority Expression] = "-TOT_Flow"
            Opts.Font = "Arial|10"
            Opts.Color = self.Colors("Gray")
            Opts.Rotation = "True"
            Opts.Visibility = "On"
            Opts.[Set Priority] = 8
            
            SetLabels(self.Layers.Links+"|ReducedLabels", lbl, Opts)
        end
    
    enditem //EndMethod
    
    //Join assignment results to the network
    Macro "JoinFlows" (FlowFile) do
    
        if GetFileInfo(FlowFile) != null then do
            self.Views.Flow = OpenTable("Flow", "FFB", {FlowFile, })
            self.Views.NetFlow = JoinViews("Network+Flow", 
                                           self.Layers.Links+".ID", 
                                           self.Views.Flow+".ID1", )
            //Close the flow view so it doesn't remain after the map is closed
            CloseView(self.Views.Flow)
        end
        else
            if TypeOf(FlowFile) = TypeOf("string") then
                Throw("Cannot join flow file to map - Flow file not Found\n"+FlowFile)
            else 
                Throw("Cannot join flow file to map - Incorrect function argument FlowFile")
		
		Return(self.Views.NetFlow)
            
    enditem
    //EndMethod
	
    //Join data to the TAZ Layer
    Macro "JoinData" (DataFile, joinID) do
    //Data file can be:
    // - DBASE / FFB / FFA / CSV
    // - Access in the form "*.dbd|TableName"
    
        //Verify that the zone layer is in the map
        if self.Layers.Zones = null then do
            ShowMessage("Cannot join data - no zone layer in map")
            Return()
        end
        
        //Identify data fileype
        fspec = SplitString(DataFile)
        ftype = RunMacro("G30 table type", fspec[1])
        
        //Access needs to know which unique ID to use
        if ftype = "ACCESS" then fspec = fspec + {joinID}
        
        //Open the table for joining
        self.Views.Data = OpenTable("Data", ftype, fspec, )
        if self.Views.Data = null then do
            ShowMessage("Error joining TAZ data to zone layer.")
            Return()
        end
        
        //Join 
        self.Views.ZoneData = JoinViews("Zones+Data", self.Layers.Zones+".ID", 
                                        self.Views.Data+"."+joinID, )
                                        
        //Close the data view so it doesn't remain after the map is closed
        CloseView(self.Views.Data)
    
    
        Return(self.Views.ZoneData)
    
    enditem
    //EndMethod
    
    //Get a select link query settings (separate dialog box)
    Macro "SelectMapSettings" (qry_file) do
        Return(RunDbox("SelectMapSettings", qry_file))
    EndItem
    //EndMethod
    
    //Get a scenario for comparison
    Macro "GetScenario" (pername) do
        Return(RunDbox("SelectCompare", pername))
    EndItem
    //EndMethod
	
	//Ask the user to select a data year, set database to this value
	Macro "SetDataYear" (mdb_file, avail_tname, act_tname) do
		Return(RunDbox("SetDataYear", mdb_file, avail_tname, act_tname))
	EndItem
	//EndMethod
    
    //Join assignment results to the network for comparison and setup map
    Macro "CompareFlows" (FlowFile, threshold) do
    
        //Default threshold for no difference
        if threshold = null then threshold = 500
        threshold = String(threshold)
    
        if GetFileInfo(FlowFile) = null or
           self.Views.Flow = null then 
            Throw("Cannot join flow file for comparison")
        
        
        //Open and join the comparison flow
        self.Views.CompareFlow = OpenTable("CompareFlow", "FFB", {FlowFile, })
        self.Views.NetCompareFlow = JoinViews("Network+Flow+CompareFlow", 
                                               self.Views.NetFlow+".ID", 
                                               self.Views.CompareFlow+".ID1", )
        CloseView(self.Views.CompareFlow)
        
        //Compute expressions
        f_vw = self.Views.Flow
        c_vw = self.Views.CompareFlow
        join_vw = self.Views.NetCompareFlow
        diff_expr = "nz(" + f_vw + ".TOT_Flow) - nz(" + 
                            c_vw + ".TOT_Flow)"
        abs_expr = "ABS(DIFF)"
        color_expr = "if ABSDIFF < " + threshold + " then 0 else DIFF/ABSDIFF"
        CreateExpression(join_vw, "DIFF", diff_expr, )
        CreateExpression(join_vw, "ABSDIFF", abs_expr, )
        CreateExpression(join_vw, "DIFFCOLOR", color_expr, )
        
        //Create color theme
        whr_colors = {self.Colors("Gray"),  //Other
                      self.Colors("Blue"),  //Down (-1)
                      self.Colors("Gray"),  //No Change (0)
                      self.Colors("DkRed")} //Up (1)
                      
        whr_names = {"Minmial Change",
                     "Decrease in Volume", 
                     "Minmial Change",
                     "Increase in Volume"}


        whr_th = CreateTheme("Direction of Change", join_vw+".DIFFCOLOR", 
                             "Categories", whr_colors.length - 1, )
        SetThemeLineColors(whr_th, whr_colors)
        ShowTheme( , whr_th)
        
        //Legend settings (Color)
		class_cnt = GetThemeClassLabels(whr_th)
		if class_cnt.length < 4 then do
			ShowMessage("Warning - insufficient differences between themes to create complete map.  Use results carefully!")
		end
		else do
			SetLegendDisplayStatus(whr_th+"|3", "False")
		end
        SetThemeClassLabels(whr_th, whr_names)
        
        //Scaled Symbol Theme
        self.Bandwidths(join_vw+".ABSDIFF")
    
    EndItem
    //EndMethod

    //Apply labels to the link layer
    Macro "Label" (expr, InOpts) do
        SetView(self.Layers.Links)
        
        //assign a unique label name
        r = R2I(Round(RandomNumber() * 100, 0))
        lbl_suffix = Format(r, "*.")
        
        //Check for expression view override
        if InOpts.ExpressionView != null then
            vw = InOpts.ExpressionView
        else
            vw = self.Views.NetFlow
        
        //Set up label expressions
        lbl = CreateExpression(vw, "lbl_"+lbl_suffix, expr, )
        self.LinkLabelExp = lbl
        if InOpts.CC.Expression != null then 
            cc_lbl = CreateExpression(vw, "cc_lbl_"+lbl_suffix, 
                                      InOpts.CC.Expression, )
        else
            cc_lbl = lbl
            
        //Set up priority expressions
        if InOpts.[Priority Expression] != null then do
			pri_exp = Substitute(InOpts.[Priority Expression], "FT", self.Settings.Network.FTField, )
            pri = CreateExpression(vw, "pri", pri_exp, )
		end
		else pri = null
        
        if InOpts.CC.[Priority Expression] != null then do
			pri_exp = Substitute(InOpts.CC.[Priority Expression], "FT", self.Settings.Network.FTField, )
            CCpri = CreateExpression(vw, "CCpri", pri_exp, )
		end
        else CCpri = pri

        //Load label options
        Opts = null
        if pri != null then Opts.[Priority Expression] = "-"+pri
        if InOpts.Font != null then 
            Opts.Font = InOpts.Font
        else
            Opts.Font = "Arial|8.5"
        if InOpts.Color != null then
            Opts.Color = InOpts.Color
        else
            Opts.Color = self.Colors("Black")
            
        CCOpts = null
        if CCpri != null then CCOpts.[Priority Expression] = "-"+CCpri
        if InOpts.CC.Font != null then 
            CCOpts.Font = InOpts.CC.Font
        else
            CCOpts.Font = "Arial|7"
        if InOpts.CC.Color != null then
            CCOpts.Color = InOpts.CC.Color
        else
            CCOpts.Color = self.Colors("Gray")

        Opts.Rotation = "True"
        CCOpts.Rotation = "True"
        Opts.Visibility = "On"
        CCOpts.Visibility = "On"
        Opts.[Set Priority] = 5
        CCOpts.[Set Priority] = 7
        
        //Activate Labels
        SetLabels(self.Layers.Links+"|", lbl, Opts)
        
        //Different settings for centroids (if selected)
        cnt = 0
        on NotFound goto next1
        cnt = GetSetCount("CentroidConnectors")
        next1:
        on NotFound default
        if cnt > 0 then 
            SetLabels(self.Layers.Links+"|CentroidConnectors", cc_lbl, CCOpts)
        
        //Highlight for validation
        if InOpts.Highlight then do
            SetView(self.Layers.Links)
            
            diff_threshold = 3000
            pct_threshold = 0.2 //Use 0.1 for a tighter check
            
            //Convert to peak period using factor of 10
            if Position(self.count_field, "AM") > 0 or Position(self.count_field, "PM") > 0 then do
                diff_threshold = diff_threshold / 10
            end
            
            pct_upper = String(1+pct_threshold)
            pct_lower = String(1-pct_threshold)
            
            SelectByQuery("OK", "Several", 
                          "Select * Where abs(TOT_Flow- "+self.count_field+")<"+String(diff_threshold)+" or " + 
                          "((TOT_Flow/"+self.count_field+")>="+pct_lower+" and " + 
                          "(TOT_Flow/"+self.count_field+"<="+pct_upper+"))", )
            SelectByQuery("High", "Several", 
                          "Select * Where (TOT_Flow- "+self.count_field+")> "+String(diff_threshold)+" and " + 
                          "(TOT_Flow/"+self.count_field+">"+pct_upper+")", )
            SelectByQuery("Low", "Several", 
                          "Select * Where (TOT_Flow- "+self.count_field+")< -"+String(diff_threshold)+" and " + 
                          "(TOT_Flow/"+self.count_field+"<"+pct_lower+")", )
                          
            //Set up defaults for new selection sets
            SetDisplayStatus("OK", "Active")
            SetDisplayStatus("Low", "Active")
            SetDisplayStatus("High", "Active")
            
            SetLineStyle(self.Layers.Links+"|OK", null)
            SetLineStyle(self.Layers.Links+"|Low", null)
            SetLineStyle(self.Layers.Links+"|High", null)
            SetLineColor(self.Layers.Links+"|OK", null)
            SetLineColor(self.Layers.Links+"|Low", null)
            SetLineColor(self.Layers.Links+"|High", null)
            
            //Set up labels for highlight selection sets
            fill_sty = RunMacro("G30 setup fill styles")
            LabelOptsColor = CopyArray(Opts)
            LabelOptsColor.[Frame Border Style] = self.Styles("None")
            LabelOptsColor.[Frame Border Color] = ColorRGB(0, 0, 0)
            LabelOptsColor.[Frame Border Width] = 0
            LabelOptsColor.[Frame Fill Color] = ColorRGB(65535, 65535, 0)
            LabelOptsColor.[Frame Fill Style] = fill_sty[2]
            LabelOptsColor.[Frame Type] = "rounded rectancle"
            LabelOptsColor.Framed = "True"
            SetLabels(self.Layers.Links+"|OK", lbl, LabelOptsColor)
            LabelOptsColor.[Frame Fill Color] = ColorRGB(47360, 56320, 65280)
            SetLabels(self.Layers.Links+"|Low", lbl, LabelOptsColor)
            LabelOptsColor.[Frame Fill Color] = ColorRGB(65280, 47360, 47360)
            SetLabels(self.Layers.Links+"|High", lbl, LabelOptsColor)
            LabelOptsColor = null
            
            
            //!!! Non-Standard separate label style for deleted count
            SelectByQuery("DeletedCount", "Several", "Select * Where CountAction = -1", )
            SetDisplayStatus("DeletedCount", "Active")
            SetLineStyle(self.Layers.Links+"|DeletedCount", null)
            
            LabelOptsDel = CopyArray(Opts)
            LabelOptsDel.Color = self.Colors("Red")
            SetLabels(self.Layers.Links+"|DeletedCount", lbl, LabelOptsDel)
            
        end //Highlight
        
    enditem
    //EndMethod
    
    //Clear all themes from the link layer
    Macro "ClearThemes" (lyr) do
        
        //Hide visible themes
        orig_lyr = GetLayer()
        SetLayer(lyr)
        th = GetDisplayedThemes(self.Map+"|"+lyr+"|")
        for i = 1 to th.Length do
            HideTheme(null, th[i])
        end
        
        //Don't destroy the themes - they may be used by another map in the 
        //workspace
        
        SetLayer(orig_lyr)
    
    enditem
    //EndMethod
	
	//Hide all layers for all sets on the identified layer
    Macro "HideLabels" (lyr) do
    // lyr: Layer to operate on.  Defaults to link layer
    
        if lyr = null then lyr = self.Layers.Links
        sets = {null} + GetSets(lyr)
        
        for set in sets do
            {vis} = GetLabelOptions(lyr+"|"+set, {"Visibility"})
            if vis then do
                SetLabelOptions(lyr+"|"+set, {{"Visibility", "Off"}})
            end
        end
    enditem //EndMethod
   
    //Clear all selection sets from the specified layer
    Macro "ClearSets" (lyr) do
        orig_lyr = GetLayer()
        SetLayer(lyr)
        sets = GetSets(lyr)
        for i = 1 to sets.length do
            if sets[i] = "Selection" then
                SelectNone("Selection")
            else 
                DeleteSet(sets[i])
        end
        SetLayer(orig_lyr)
    EndItem
    //EndMethod
    
    //Add a bandwidth theme to the link layer
    Macro "Bandwidths" (FieldSpec, InOpts) do
        //InOpts:
        // - Data Source: "Screen" to override default "All"
        // - Line Style: Line style to override devault "Double"
        // - ThemeName: Name to override default "Volume Bandwidths"
        // - CreateOnly: True to create but not show the theme
    
        Opts = null
        if InOpts.[Data Source] = "Screen" then 
            Opts.[Data Source] = "Screen"
        if InOpts.[Line Style] = null then 
            line_style = "Double"
        else
            line_style = InOpts.[Line Style]
        if InOpts.ThemeName != null and TypeOf(InOpts.ThemeName) = TypeOf('str') then 
            ThemeName = InOpts.ThemeName
        else 
            ThemeName = "Volume Bandwidths"
            
        bd_theme = CreateContinuousTheme(ThemeName, {FieldSpec}, Opts)
        ShowTheme( , bd_theme)
        SetLegendDisplayStatus(bd_theme, "False")
        
        //Set the line style if the field starts with AB or BA
        t = ParseString(FieldSpec, '.')
        t = Upper(Left(t[2], 2))
        if t = 'AB' or t = 'BA' then do
            //SetThemeLineStyles(bd_theme, {self.Styles('Double')})
            SetThemeLineStyles(bd_theme, {self.Styles(line_style)})
            SetThemeLineColors(bd_theme, {self.Colors('BrtGreen')})
            SetThemeLineWidths(bd_theme, {3})
        end
        
        if !InOpts.CreateOnly then do
            ShowTheme( , bd_theme)
        end
        
        Return(bd_theme)
    
    enditem
    //EndMethod
	
	Macro "Shading" (FieldSpec, method, classes , InOpts) do
        //InOpts:
        // - Data Source: "Screen" to override default "All"
        // - Color: Color to override default blue
        // - ThemeName: Name to override default "Density"
        // - CreateOnly: True to create but not show the theme
        
        ZoneLayer = self.Layers.Zones
        orig_lyr = GetLayer()
        SetLayer(ZoneLayer)
        Opts = null
        if InOpts.[Data Source] = "Screen" then 
            Opts.[Data Source] = "Screen"
        if InOpts.[Color] = null then Color = self.Colors("Blue")
        else Color = InOpts.[Color]
        if InOpts.ThemeName != null and TypeOf(InOpts.ThemeName) = TypeOf('str') then 
            ThemeName = InOpts.ThemeName
        else 
            ThemeName = "Density"
            
        sh_theme = CreateTheme(ThemeName, FieldSpec, method, classes, Opts)
        SetLegendDisplayStatus(sh_theme, "True")

        //Setup color gradient
        palette = GeneratePalette(self.Colors("White"), Color, classes-1, )
        for cls = 1 to palette.length do
            cls_id = ZoneLayer + "|" + sh_theme + "|" + String(cls)
            SetFillColor(cls_id, palette[cls])
            SetFillStyle(cls_id, solid)
        end
        
        if !InOpts.CreateOnly then do
            ShowTheme( , sh_theme)
        end
        
        SetLayer(orig_lyr)
        Return(sh_theme)
        
    enditem
    //EndMethod

    //Add an LOS color theme to the map
    Macro "LOS" (Field) do
    
        //Setup colors and names
        los_colors =   {self.Colors("Gray"),     //Other
                        self.Colors("Green"),    //A
                        self.Colors("Green"),    //B
                        self.Colors("Green"),    //C
                        self.Colors("Orange"),   //D
                        self.Colors("Orange"),   //E
                        self.Colors("Red"),      //F
                        self.Colors("Gray")}     //n/a
                        
        los_names = {"Not Computed",
                     "Uncongested (A - C)",
                     "Uncongested (A - C)",
                     "Uncongested (A - C)",
                     "Congesting (D - E)",
                     "Congesting (D - E)",
                     "Congested (F)", 
                     "Not Computed"}
        
        //Create and show the theme
        los_th = CreateTheme("LOS", self.Views.NetFlow+"."+Field, 
                             "Categories", los_names.length -1, ) 
                             //-1 because names also include "Other"
                             
        SetThemeLineColors(los_th, los_colors)
        ShowTheme( , los_th)
        
        //Hide redundant legend entries
        SetLegendDisplayStatus(los_th+"|1", "False")
        SetLegendDisplayStatus(los_th+"|2", "False")
        SetLegendDisplayStatus(los_th+"|3", "False")
        SetLegendDisplayStatus(los_th+"|5", "False")
        
        SetThemeClassLabels(los_th, los_names)   
    
    enditem
    //EndMethod
    
    //Add a V/C ratio color theme to the map
    Macro "VOC" (Field) do
    
        if Field = null then Field = "AB_VOC"
    
        //LOS VC values based on arterial cutpoints
        vc_values = {{0.00, "True", 0.51, "False"},   //A
                     {0.51, "True", 0.67, "False"},   //B
                     {0.67, "True", 0.79, "False"},   //C
                     {0.79, "True", 0.90, "False"},   //D
                     {0.90, "True", 1.00, "False"},   //E
                     {1.00, "True", 9999, "False"}}   //F

        vc_colors = {self.Colors("Gray"),       //Other
                     self.Colors("Green"),      //A
                     self.Colors("Green"),      //B
                     self.Colors("Green"),      //C
                     self.Colors("Orange"),     //D
                     self.Colors("DkOrange"),   //E
                     self.Colors("Red")}        //F


          
        //Create and show the theme
        vc_th = CreateTheme("V/C", self.Views.NetFlow+"."+Field, 
                            "Manual", vc_values.length, {{"Values", vc_values}})
                            
        SetThemeLineColors(vc_th, vc_colors)
        ShowTheme( , vc_th)
                            
    
    EndItem
    //EndMethod

    //Redraw the map and update the map toolbar
    Macro "Redraw" do
        RedrawMap(self.Map)
        RunMacro("G30 update map toolbar")
    enditem
    //EndMethod

	//**************************************************************************
	//** Macro to apply a FT color theme and save settings to the DBD file
	Macro "NetworkSetting" (dbd_file, close, save) do
	//** String dbd_file = Name of the network file
    //** Boolean close = True to close the map on finish, or False (default) to 
    //**  leave the map open
    //** Boolean save = True to save settings to the "stg" file, or False to 
    //** simply apply the settings
    //**
    //** This macro relies on the settings specified in the Settings property
    //**************************************************************************
	
NextStep= "Map Setup"
        //Settings
        NetSet = self.Settings.Network
    
		//Open the dbd file in a map
		self.Create(dbd_file, close) //if close=True, then StopRedraw parameter is True
		
		//Remove any pre-existing link themes
		self.ClearThemes(self.Layers.Links)
        self.ClearThemes(self.Layers.Nodes)
        
//EndStep
NextStep= "FT Theme"

        self.FTTheme()
        
//EndStep
NextStep= "Link Selection Sets"

        //Clear/remove all sets
        SetLayer(self.Layers.Links)
        self.ClearSets(self.Layers.Links)
        
        //Centroid connectors
        cc_qry = "Select * Where " + NetSet.FTField + " = " + 
                 String(NetSet.CCValue)
        SelectByQuery("CentroidConnectors", "Several" ,cc_qry, )
        SetDisplayStatus(self.Layers.Links+"|CentroidConnectors", "Active")
        
//EndStep
NextStep= "Node Theme"     

        //Set nodes with ZONE > 0 to a blue triangle, other nodes to an orange
        //  target.  Leaves the basic node style unchanged.
        SetLayerVisibility(self.Layers.Nodes, "True")
        SetLayer(self.Layers.Nodes)
        
        Opts = null
        Opts.Values = {{0, "True", 999999999999999999, "True"}}
        
        node_th = CreateTheme("Node Type", self.Layers.Nodes+".ZONE", "Manual", 1, Opts)
        
        SetThemeClassLabels(node_th, {"Nodes", "Centroids"})
        SetThemeIcons(node_th, {{"Font Character", "Caliper Cartographic|8", 38},
                                {"Font Character", "Caliper Cartographic|6", 39}})
        SetThemeIconColors(node_th, {self.Colors("Orange"), self.Colors("Blue")})
        ShowTheme( , node_th)
    
//EndStep
NextStep= "Node Selection Sets"  

        self.ClearSets(self.Layers.Nodes)
        SetLayer(self.Layers.Nodes)
        c_qry = "Select * Where ZONE > 0"
        SelectByQuery("Centroids", "Several" ,c_qry, )
        SetDisplayStatus(self.Layers.Nodes+"|Centroids", "Active")

//EndStep
NextStep= "Save Settings"

		//Save the theme as the default display for the link layer
        self.Redraw()
		t = SplitPath(dbd_file)
		sty_file = t[1]+t[2]+t[3]+".sty"
		SetDefaultDisplay(self.Layers.Links, sty_file)
        sty_file = t[1]+t[2]+t[3]+"_.sty"
		SetDefaultDisplay(self.Layers.Nodes, sty_file)
		
//EndStep
NextStep= "Close the map"
        
        if close then CloseMap(self.Map)
		
//EndStep	
	//EndMethod
    EndItem
    
	//**************************************************************************
	//** Macro to apply a FT color theme to an open map
	Macro "FTTheme" do
    
        NetSet = self.Settings.Network
    
        SetLayer(self.Layers.Links)
		//Create the link theme (Include all values up to 99 unique numbers)
		ft_theme = CreateTheme("Roadways", self.Layers.Links+"."+NetSet.FTField, 
                               "Categories", 99, )
		ft_thvals = GetThemeClassValues(ft_theme) //First element null for other
        
        //Re-format FT options for use in theme settings.  While we're at it, 
        //  make sure that the passed values line up correctly with the actual
        //  theme values.  This will help prevent problems when a particular 
        //  value is missing or when there is an extra value in the file.
        dim ft_labels[ft_thvals.Length]
        dim ft_widths[ft_thvals.Length]
        dim ft_colors[ft_thvals.Length]
        dim ft_styles[ft_thvals.Length]
        Ks = self.UT.Keys(NetSet.FT)
        Vs = self.UT.Values(NetSet.FT)
        for i = 1 to Ks.Length do
            k = Ks[i] //FT Description
            v = Vs[i]
            //v = {FTval, width, color, style}
            if v[1] != null then idx = ArrayPosition(ft_thvals, {v[1]}, )
            else idx = 1 //Other in the first slot
            if idx > 0 then do
                ft_labels[idx] = string(v[1]) + " - " + k
                ft_widths[idx] = v[2]
                ft_colors[idx] = self.Colors(v[3])
                ft_styles[idx] = self.Styles(v[4])
            end
        end
        
        //Add labels for FT values not included in the options
        for i = 1 to ft_labels.length do
            if ft_labels[i] = null then do
                if i = 1 then ft_labels[i] = "Other"
                else ft_labels[i] = String(ft_thvals[i])
            end
        end
		
        //Apply settings
		SetThemeClassLabels(ft_theme, ft_labels)
		SetThemeLineStyles(ft_theme, ft_styles)
        SetThemeLineColors(ft_theme, ft_colors)
		SetThemeLineWidths(ft_theme, ft_widths)
		
		//Show the theme
		ShowTheme( , ft_theme)
		
		Return(ft_theme)
        
    enditem
    //EndMethod
    
    
    //Macro to return a color based on a name (or a list of colors)
    Macro "Colors" (color) do
        //Define a colors attribute for easy reference
        Colors = null
        Colors.Gray = ColorRGB(32768,32768,32768) //The standard "TransCAD Gray"
        Colors.LtGray = ColorRGB(49152,49152,49152)
        Colors.DkGray = ColorRGB(16384, 16384, 16384)
        Colors.Black = ColorRGB(0, 0, 0)
        Colors.BlueGreen = ColorRGB(0, 49152, 49152)
        Colors.Red = ColorRGB(65535, 0, 0)
        Colors.DkRed = ColorRGB(49152, 1228, 0)
        Colors.BrtGreen = ColorRGB(0, 65535, 0)
        Colors.DkGreen = ColorRGB(0, 18384, 0)
        Colors.Green = ColorRGB(0, 49512, 0)
        Colors.Blue = ColorRGB(0, 0, 65535)
        Colors.LtBlue = ColorRGB(0, 44032, 65535)
        Colors.DkBlue = ColorRGB(0, 0, 32768)
        Colors.Orange = ColorRGB(65535, 49152, 0)
        Colors.LtOrange = ColorRGB(65280, 59648, 42496)
        Colors.DkOrange = ColorRGB(65535, 32768, 0)
		Colors.Cyan = ColorRGB(0, 65535, 65535)
		Colors.White = ColorRGB(65535, 65535, 65535)
        
        if color = null or Colors.(color) = null then
            Return(Colors)
        else 
            Return(Colors.(color))
    EndItem
    //EndMethod
    
    //Macro to return a style based on a name (or a list of styles)
    //Pass a style name to get a style name, or pass "List" to get a list of
    //available styles.  Returns null if an invalid style is passed.
    Macro "Styles" (style) do
        sty = RunMacro("G30 setup line styles")
        Styles.None = sty[1]
        Styles.Solid = sty[2]
        Styles.Dot = sty[3]
        Styles.Dash = sty[6]
        Styles.Double = sty[69]
        
        if Lower(style) = "List" then
            Return(Styles)
        if style = null then
            Return(null)
        else 
            Return(Styles.(style))
    enditem
    //EndMethod
        
    Macro "LabelingToolbox" do
        RunDbox("Labeling Toolbox", self)
        Return(1)
    enditem //EndMethod
        
EndClass

//******************************************************************************
//** Mapper dialog box: ask for a scenario for comparison                     **
Dbox "SelectCompare" (per) title: "Comparison Map"                                //**
// NOTE - this access the scenario files through a shared variable, AND       **
//        references file keys by name -                                      **
// THIS IS A "HIGH MAINTENENCE" DIALOG BOX                                    **
//******************************************************************************

    init do
        //Get completed scenarios
        shared Scen
        
        ScenList = null
        FlowList = null
        
        
        //Get selected scenario flow file for reference
        Args = Scen.Control.Simplified(Scen.Arr[Scen.Vars.ScenFlag[1]][2])
        if per = "DY" then scen_flow = Args.[DY Highway Flows]
        else do
            scen_flow = Args.[Highway Flows]
            scen_flow = Substitute(scen_flow, "%PER_HWY%", per, )
        end
        
        for i = 1 to Scen.Arr.Length do
        
        //Don't add current scenario
            if i <> Scen.Vars.ScenFlag[1] then do
                //Don't add if daily flow file is not present
                Args = Scen.Control.Simplified(Scen.Arr[i][2])
                base_name = Scen.Arr[i][1]
                
                if per = "DY" then base_flow = Args.[DY Highway Flows]
                else do
                    base_flow = Args.[Highway Flows]
                    base_flow = Substitute(base_flow, "%PER_HWY%", per, )
                end
                
                if GetFileInfo(base_flow) <> null then do
                    ScenList = ScenList + {base_name}
                    FlowList = FlowList + {base_flow}
                end
            end
        end //end loop over available scenarios
        
        if ScenList = null then do
            ShowMessage("No completed scenarios exist for comparison")
            Return()
        end
        
        BaseFlag = 1  //Start with first scenario in the list
    enditem //init
    
    text 1, 1 Variable: "Select a baseline scenario for comparison:"
    popdown Menu "Baseline" 3, 2.5, 30 List: ScenList Variable: BaseFlag
    button "OK" 15, 5.5, 10, 1.5 do
        if base_flow = scen_flow then do
            ShowMessage("Scenarios reference the same output flow file.  Cannot create comparison map.")
            Return()
        end
        Return(FlowList[BaseFlag])
    enditem
    button "Cancel" 26, 5.5, 10, 1.5 do
        Return()
    enditem

EndDbox


//******************************************************************************
//** Mapper dialog box: select link query map settings                        **
Dbox "SelectMapSettings" (qry_file)                                         //**
     title: "Select Link/Node Map"                                          //**

    init do
        //Get list of querys
        shared UT
        sel_list = UT.SelectList(qry_file)
        sel_val = 1
    
    enditem
    
    text "Query: " 1, 1
    popdown menu "QueryName" 13, 1, 15, 5 list: sel_list variable: sel_val
    
    button "OK" 16, 5, 7, 1.5 do
        RetOpts = null
        RetOpts.QueryName = sel_list[sel_val]
        Return(RetOpts)
    enditem
    button "Cancel" after, same, 7, 1.5 do
        Return()
    enditem
    

EndDbox

//******************************************************************************
//** Labeling Toolbox                                                       **

Dbox "Labeling Toolbox" (MP) toolbox

    init do
    
        //Could be set externally to make more general, with a max number
        // of types
        qry_list = {"Freeway": "FT = 1 or FT = 2", 
                    "Principal": "FT = 3", 
                    "Minor": "FT = 4", 
                    "Collector": "FT = 5 or FT = 6", 
                    "Local": "FT = 7 or FT = 9",
                    "Ramp": "FT = 11 or FT = 12"}
                    
        never_qry = "FT BETWEEN 81 and 98"
        
        //Checkbox settings
        dim ft_stat[qry_list.length]
        for ii = 1 to ft_stat.length do ft_stat[ii] = 1 end
        
    enditem
    
    checkbox "FT1" 1, 1        prompt: qry_list[1][1] variable: ft_stat[1]
    checkbox "FT2" same, after prompt: qry_list[2][1] variable: ft_stat[2]
    checkbox "FT3" same, after prompt: qry_list[3][1] variable: ft_stat[3]
    checkbox "FT4" same, after prompt: qry_list[4][1] variable: ft_stat[4]
    checkbox "FT5" same, after prompt: qry_list[5][1] variable: ft_stat[5]
    checkbox "FT6" same, after prompt: qry_list[6][1] variable: ft_stat[6]

    button "Update" 1, 8, 10, 1.5 do
        MP.ReduceLabels(qry_list, ft_stat)
        RedrawMap(MP.Map)
    enditem


    button "Close" after, same, 10, 1.5 do
        RunMacro("close")
    enditem

    close do
        RunMacro("close")
    enditem
    
    macro "close" do
    
        /* //Option to re-show main dbox, but
           //  currently just leaving both visible
        shared model_ui
        on NotFound goto close_anyway
        SetLibrary(model_ui)
        ShowDbox("SEMCOG Model")
        
        close_anyway:
        SetLibrary()
        */
        Return()
    enditem
        

EndDbox