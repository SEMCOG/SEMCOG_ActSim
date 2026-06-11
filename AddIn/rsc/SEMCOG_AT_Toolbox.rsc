//Area Type editing toolbox.
//
// - The fields AT2015 (integer) must be present on the TAZ and link layer before starting.
// - To calculate future year AT:
// 1. Create a field in the TAZ layer named ATyyyy (e.g., AT2045)
// 2. Optionally fill with valeus from the base year AT
// 3. Run the utility, and select the forecast year (2045)
// 4. Click "Recalculate"
//    - Optionally modify the algorithm in CalcZoneAT to better compute future 
//      year area types.
// 5. Optionally perform manual smoothing.





Macro "CalcZoneAT" (join_vw, dist_join_vw, DataYear)

    //Define query to select CBD only area types
    cbd_qry = "Select * where AT"+DataYear+" > 1"  //These will be updated when recalculating base year AT. CBDs will not be changed.
    //Define query to select CBD and urban area types
    change_qry = "Select * where AT"+DataYear+" > 2 or nz(AT"+DataYear+") = 0"  //These will be updated when recalculating forecast AT. CBDs and Urban EAAs will not be changed.
    //Define query to select Wayne and Washtenaw Counties
    county_qry = "Select * where Zones.COUNTY = 2 or Zones.COUNTY = 5" 
    //Define query to select Detroit only
    detroit_qry = "Select * where Zones.COUNTY = 1"

    SetView(join_vw)
    SelectByQuery("Selection", "Several", change_qry, )

    //Load data
    DEN = GetDataVector(join_vw+"|Selection", "Density", )
    
    //Compute TAZ-based AT for non-Wayne County
    // Disabled... >= 12000 to CBD, let the user define this manually.
    AT = if DEN >= 5500 then 2 else if DEN >= 2500 then 3 else if DEN >= 500 then 4 else if DEN = 0 then 0 else 5

    SetDataVector(join_vw+"|Selection", "AT"+DataYear, AT, )
    
    //Apply District level AT to Detroit, all districts are at least urban
    SetView(dist_join_vw)
    SelectByQuery("Selection", "Several", change_qry, )   
    SelectByQuery("Selection", "Subset", detroit_qry, )   
 
    DEN = GetDataVector(dist_join_vw+"|Selection", "Dist_Density", )
 
    AT = if DEN >= 5000 then 2 else if DEN >= 0 then 3 else 0
    SetDataVector(dist_join_vw+"|Selection", "AT"+DataYear, AT, )  

    //Apply District level AT to Wayne (Non-Detroit) and Washtenaw counties
    SetView(dist_join_vw)
    SelectByQuery("Selection", "Several", change_qry, )   
    SelectByQuery("Selection", "Subset", county_qry, )   
 
    DEN = GetDataVector(dist_join_vw+"|Selection", "Dist_Density", )
    AT = if DEN >= 5000 then 2 else if DEN >= 2500 then 3 else if DEN >= 750 then 4 else if DEN = 0 then 0 else 5

    SetDataVector(dist_join_vw+"|Selection", "AT"+DataYear, AT, )  

    Return(1)
    
EndMacro


Dbox "Area Type" (Args) NoKeyboard
	toolbox
    
	init do //StartMethod

        shared UT, ui_dir
    
		//Load information
        bmp_dir = ui_dir + "bmp\\"
        dbd_file = Args.[Highway DB]
        taz_file = Args.[TAZ]
        
        t = SplitPath(dbd_file)
        
        //Use input TAZ file or processed TAZ file, depending on settings
        run_disagg = Args.RunDisaggModels
        if run_disagg then do
            sed_file = Args.[TAZ Data Table]
            if GetFileInfo(sed_file) = null then do
                Throw("The Area Type processor requires SED Processing to have been run when set to run Disaggregate Models.")
                Return()
            end
        end else do
            sed_file = Args.[Processed TAZ Data]
            if GetFileInfo(sed_file) = null then do
                Throw("The Area Type processor requires input SED when set to skip Disaggregate Models.")
                Return()
            end
        end
        
        DataYear = "2015" 
        NetYear = "2015"
        
        BaseYear = "2015" //Use to show difference between current and base year
		
		//define colors for the map
		colors = RunMacro("G30 setup colors")
		fills  = RunMacro("G30 setup fill styles")
		styles = RunMacro("G30 setup line styles")

		//Define Area Types
		at_names = {"CBD", "Urban EAA", "Urban", "Suburban", "Rural"}
		at_nums  = {1,         2,           3,       4,          5     }
		
		//define icon files
        tool_file = bmp_dir + "AT_Tool"
		
        //Create a map to start with
		RunMacro("CreateMap")
        
        //Start with 1 (zone) or 2 (network)
        
		//Create dropdown map type menu
		pop = {"Zone", "Network"}
		pop_index = 1 //Default to zones
        RunMacro("UpdateMap")
		
	enditem //end init EndMethod
	
	//Macro to open all files and create the working map.
	//when the data year is changed, the map is re-created.
	macro "CreateMap" do //StartMethod
	
        //Close map if it already exists
		if map <> null then SetMapSaveFlag(map, "False")
		RunMacro("G30 File Close All")
	
    	//Open TAZ layer in a new map
    	layers = GetDbLayers(taz_file)
		taz_lyr = layers[1]
		info = GetDbInfo(taz_file)
		taz_scope = info[1]
		Opts = null
		Opts.Locked = "True"
		Opts.Scope = taz_scope
		map = CreateMap("Area Type", Opts)
		taz_lyr = AddLayer(map, taz_lyr, taz_file, taz_lyr)
  		RunMacro("G30 new layer default settings", taz_lyr)
		SetLayer(taz_lyr)
		SelectNone("Selection")

		//Add the roadway layer to the map
		layers = GetDbLayers(dbd_file)
		node_lyr = layers[1]
		link_lyr = layers[2]
		link_lyr = AddLayerEx(map, link_lyr, dbd_file, link_lyr, )
		RunMacro("G30 new layer default settings", link_lyr)
		node_lyr = AddLayerEx(map, node_lyr, dbd_file, node_lyr, )
		RunMacro("G30 new layer default settings", node_lyr)
		SetLayerVisibility(map+"|"+node_lyr, "False")
		SetLayer(node_lyr)
		SelectNone("Selection")
		SetLayer(link_lyr)
		SelectNone("Selection")
        SetArrowheads (link_lyr+"|", "None")
        
        //Check for AT field for current year, fail with error message if needed.
        {flds,} = GetFields(taz_lyr, "All")
        if ArrayPosition(flds, {"AT"+DataYear}, ) = 0 then do
            ShowMessage("Missing required TAZ layer field AT"+DataYear+", exiting.\n\nPlease add the field and try again.")
            Return()
        end
        {flds,} = GetFields(link_lyr, "All")
        if ArrayPosition(flds, {"AREA_TYPE"}, ) = 0 then do
            ShowMessage("Missing required network field AREA_TYPE, exiting.\n\nPlease add the field and try again.")
            Return()
        end
        
		//Get available DATA years
		Fields = GetFields(taz_lyr, "Integer")
		Fields = Fields[1]
		DataYears = null
		for i = 1 to Fields.length do
			if left(Fields[i],2) = "AT" then
			DataYears = DataYears + {Substring(Fields[i],3, )}
		end
        
        //Get active year index
		DataIndex = ArrayPosition(DataYears, {DataYear}, )
		if nz(DataIndex) = 0 then DataIndex = 1 //Set to the first available year if a match is not found
		DataYear = DataYears[DataIndex]

		//Open the SED file and join to the TAZ layer
        t = SplitPath(sed_file)
		sed_vw = OpenTable(t[3], "FFB", {sed_file, }) 
		join_vw = JoinViews("AT view", taz_lyr+".TAZCE10_N", sed_vw+".TAZCE10_N", )
        
        //Compute density
        //!!!RegPop = VectorStatistic(GetDataVector(join_vw+"|", "HHPop", ), "SUM", )
        //!!!RegEmp = VectorStatistic(GetDataVector(join_vw+"|", "HHPop", ), "SUM", )
        CreateExpression(join_vw, "Density", "(EmpPrinc + Households) / Area", )

        //Aggregate to Districts and compute district density. Join to TAZs.
        district_file = GetTempFileName(".bin")
        district_vw = AggregateTable("District View", join_vw + "|", "MEM", district_file, "District", {{"Households","sum", },{"EmpPrinc","sum", },{"Area","sum", } }, null)  
        CreateExpression(district_vw, "Dist_Density", "(EmpPrinc + Households) / Area", ) 
        dist_join_vw = JoinViews("District Join View", taz_lyr+".District", district_vw+".District", )

        
		//Set up the active layer and view
		SetLayer(taz_lyr)
		
	enditem //Create Map EndMethod
	
	
	//Macro to re-compute area type
	macro "ComputeAT" do //StartMethod
	
		SetMapRedraw(, "False")
	
	    //Re-compute zone AT
		//(re-compute network AT follows)
		if pop[pop_index] = "Zone" then do
		
			//For the base year:
			if DataYear = BaseYear then do

				Opts = null
				Opts.Caption = "Warning"
				Opts.Buttons = "YesNo"
				Opts.Icon = "Warning"
				Opts.Default = 2

				ans = MessageBox("Recompute Area Type for the BASE YEAR??!! ("+DataYear+")\n\n *** THIS ACTION IS NOT RECOMMENDED! ***", Opts)
            //For the forecast year
			end else do
				Opts = null
				Opts.Caption = "Question"
				Opts.Buttons = "YesNo"
				Opts.Icon = "Question"
				Opts.Default = 2

				ans = MessageBox("Compute Area Type Changes for " + DataYear + " ?\nThis action cannot be undone!", Opts)
			end //end if DataYear = 2005
            
            if ans = "Yes" then do
                RunMacro("CalcZoneAT", join_vw, dist_join_vw, DataYear)
            end
			
			SelectNone("Selection")
		end //end if map type is data
		
		//If a network map is selected
		else do

			Opts = null
			Opts.Caption = "Question"
			Opts.Buttons = "YesNo"
			Opts.Icon = "Question"
			Opts.Default = 2
			ans = MessageBox("Compute Network Area Type for " + NetYear + " based on " + DataYear + " TAZs?\nThis action cannot be undone!", Opts)
			if ans = "Yes" then do
            
                Opts = null
                Opts.LinkField = "AREA_TYPE"
                Opts.ZoneField = "AT"+DataYear
                Opts.Buffer = 0.05
                Opts.Verbose = "False"
                //ShowMessage("Procedure not available.  Link AT is now computed as part of the model stream.")
                RunMacro("CalcLinkAT", link_lyr, taz_lyr, Opts)
                
			end
		end

		end_recompute:
		
		SetMapRedraw(, "True")
		RunMacro("UpdateMap")
	
	enditem //end macro "ComputeAT" EndMethod
	
    //StartMethod - Layer Selection
	text "Layer: " 1, 1
	popdown menu "MapType" 10, 1, 10, 10 List: pop Variable: pop_index do
		RunMacro("UpdateMap")
	enditem
	
	text "Data: " 1, 2.5
	popdown menu "Data Year" 10, 2.5, 10, 10 List: DataYears Variable: DataIndex do
        
		//Set the data year
        DataYear = DataYears[DataIndex]
		RunMacro("CreateMap")  //Close and re-create map using new data
        RunMacro("UpdateMap")
        
	enditem
    
    //WARNING: Shown when the Network layer is selected.
    button "LinkWarning" 22, 1 icon: bmp_dir+"Warning.bmp" do
        msg = "Editing network AT with this tool is not recommended.\n\nLink AT is automatically calculated by the travel during the network processing step."
        MessageBox(msg, {Caption:'Link Edit Warning', Icon:'Warning', Buttons:'OK'})
    enditem
	
	//EndMethod
    
	macro "UpdateMap" do //StartMethod
	
		SetMapRedraw(, "False")
		
		//Remove any pre-existing themes from the taz layer
		SetLayer(taz_lyr)
		taz_shown = GetDisplayedThemes(taz_lyr)
		if taz_shown <> null then do
			for i = 1 to taz_shown.length do
				HideTheme(,taz_themes[i])
			end
		end
		taz_themes = GetThemes(taz_lyr)
		if taz_themes <> null then do
			for i = 1 to taz_themes.length do
				DestroyTheme(taz_themes[i])
			end
		end

		//Remove any pre-existing themes from the link layer
		SetLayer(link_lyr)
		link_shown = GetDisplayedThemes(link_lyr)
		if link_shown <> null then do
			for i = 1 to link_shown.length do
				HideTheme(,link_themes[i])
			end
		end
		link_themes = GetThemes(link_lyr)
		if link_themes <> null then do
			for i = 1 to link_themes.length do
				HideTheme(,link_themes[i])
				DestroyTheme(link_themes[i])
			end
		end
		
        //Set Up Map for when TAZ data is selected:
		if pop[pop_index] = "Zone" then do
		
		    // Non-map related items...
			ChangeField = "AT" + DataYear  //Set field that is changed with tool buttons
			
			//Set up the DARK AT theme
			SetLayer(taz_lyr)
			Opts = null
  			Opts.Values = {1,2,3,4,5}
  			at_theme      = CreateTheme("Area Type", join_vw+".AT"+DataYear, "Manual", 5, Opts)
			SetThemeFillColors(at_theme,      {colors[3], colors[19], colors[32], colors[17],  colors[7], colors[12]})
			ShowTheme(,at_theme)
			
        	//Define Link FT color/Linestyle theme
			SetLayer(link_lyr)
			Opts = null
  			Opts.Values = {1,2,3,4,5,6,7}
			ft_theme = CreateTheme("Facility Type", link_lyr+".NFC", "Manual", 7, Opts)
		                             	//other        1         2           3          4           5           6           7                   
			SetThemeLineColors(ft_theme, {colors[75], colors[1], colors[23], colors[5], colors[25], colors[17], colors[37], colors[1]  })
			SetThemeLineStyles(ft_theme, {styles[6],  styles[2], styles[2],  styles[2], styles[2],  styles[2],  styles[2], styles[2]   })
			SetThemeLineWidths(ft_theme, {1,          2,         2,          1,         1,          1,          1,         1           })
			ShowTheme(,ft_theme)
			
		end //end if mapping TAZs
		
		//Network AT map
		if pop[pop_index] = "Network" then do
		
		    // Non-map related items...
			ChangeField = "AREA_TYPE"  //Set field that is changed with tool buttons
		
			//Set up the LIGHT AT theme
			SetLayer(taz_lyr)
			Opts = null
  			Opts.Values = {1,2,3,4,5}
  			at_theme      = CreateTheme("Area Type", join_vw+".AT"+DataYear, "Manual", 5, Opts)
			SetThemeFillColors(at_theme,      {colors[3], colors[55], colors[64], colors[40], colors[45], colors[53]})
			ShowTheme(,at_theme)
			
			
			//Define Link AT color theme
			SetLayer(link_lyr)
			Opts = null
			Opts.Values = {1,2,3,4,5}
			atlink_theme = CreateTheme("Link AREA_TYPE", link_lyr+".AREA_TYPE", "Manual", 5, Opts)
		                                	//other       1           2           3           4            5
			SetThemeLineColors(atlink_theme, {colors[34],  colors[19], colors[32],  colors[17], colors[7],  colors[12]})
			SetThemeLineStyles(atlink_theme, {styles[2],  null,       null,       null,       null,        null })   //pattern theme overrides nulls
			SetThemeLineWidths(atlink_theme, {1,          null,       null,       null,       null,        null })
			ShowTheme(,atlink_theme)
			
			//Define a link FT pattern theme
			Opts = null
			Opts.Style = "True"
  			Opts.Values = {1,2,3,4,5,6,7}
			ftpattern_theme = CreateTheme("Facility Type Patterns", link_lyr+".NFC", "Manual", 7, Opts)
		                                     	//other      1          2           3          4           5           6          7                    
			SetThemeLineStyles(ftpattern_theme, {styles[6],  styles[2], styles[2],  styles[2], styles[2],  styles[2],  styles[2], styles[2],  })
			SetThemeLineWidths(ftpattern_theme, {1,          3,         3,          2,         2,          2,          2,         2,          })
			ShowTheme(,ftpattern_theme)
		
		end //end if mapping NETWORK
		
		
		//Set up a theme to show AT changes - only if not working with base year
		//This is done for both network and taz maps
		if DataYear <> BaseYear then do
			SetLayer(taz_lyr)
			CreateExpression(join_vw, "Changes",  "If AT"+BaseYear+" <> AT"+DataYear+" then 2 else 1" , )
			Opts = null
			Opts.Values = {1, 2}
			Opts.Style = "True"
			SetLayer(taz_lyr)
			change_theme = CreateTheme("Changes", join_vw+".Changes", "Manual", 2, Opts)
			SetThemeFillStyles(change_theme, {fills[1], fills[2], fills[15]})
			ShowTheme(,change_theme)
		end
		
		if pop[pop_index] = "Network" then SetLayer(link_lyr)
		else SetLayer(taz_lyr)
		
		SetMapRedraw(, "True")
		RedrawMap()
		RunMacro("G30 update map toolbar")
        
        //Show a warning when selecting network
        if pop_index = 1 then HideItem("LinkWarning")
        else ShowItem("LinkWarning")
	
	enditem //end macro "UpdateMap" EndMethod

	macro "SetAT" do //StartMethod

		cur_lyr = GetLayer()
		cur_vw = GetView()

		rec = LocateNearestRecord(location, 10)

		if cur_vw.(ChangeField) <> cur_at then do
			cur_vw.(ChangeField) = cur_at
			RedrawMap()
		end
	enditem //EndMethod

    //StartMethod - Tool Area
 	//tool "Rural" 1, 5.5 icons: rural_up do
 	tool "CBD" 1, 5.5 icon: tool_file+"|1" help: "Set area type to CBD (1)" do
		location = ClickCoord()
		cur_at = 1
		RunMacro("SetAT")
	enditem

	tool "Urban EEA" same, after icon: tool_file+"|2" help: "Set area type to Urban EEA (2)" do
		location = ClickCoord()
		cur_at = 2
		RunMacro("SetAT")
	enditem

	tool "Urban" same, after icon: tool_file+"|3" help: "Set area type to Urban (3)" do
		location = ClickCoord()
		cur_at = 3
		RunMacro("SetAT")
	enditem

	tool "Suburban" same, after icon: tool_file+"|4" help: "Set area type to Suburban (4)" do
		location = ClickCoord()
		cur_at = 4
		RunMacro("SetAT")
	enditem

	tool "Rural" same, after icon: tool_file+"|5" help: "Set area type to Rural (5)" do
		location = ClickCoord()
		cur_at = 5
		RunMacro("SetAT")
	enditem
    


	tool "?" same, after icon: tool_file+"|6" cursor: "Info" do
		location = ClickCoord()
		
		if pop[pop_index] = "Zone" then do

			SetLayer(taz_lyr)
			SetView(join_vw)
			rec = LocateNearestRecord(location, 10)

			ShowMessage(BaseYear+" AT:....."+string(join_vw.('AT'+BaseYear)) + " - " + at_names[join_vw.('AT'+BaseYear)]+ "\n"+
			           	DataYear+" AT:....."+string(join_vw.("AT"+DataYear)) + " - " + at_names[join_vw.("AT"+DataYear)] + "\n\n" )
                        /*
					   	"2005:\n" +
					   	"    Pop/Sq. Mile.."+format(join_vw.PopDensity2005, "*,0.") + "\n" +
					   	"    Emp/Sq. Mile.."+format(join_vw.EmpDensity2005, "*,0.") + "\n" + "\n\n" +
					   	DataYear + ":\n" +
					   	"    Pop/Sq. Mile.."+format(join_vw.PopDensity, "*,0.") + "\n" +
					   	"    Emp/Sq. Mile.."+format(join_vw.EmpDensity, "*,0.") + "\n")*/
		end //end info on TAZ layer
		else if pop[pop_index] = "Network" then do
			
			SetLayer(link_lyr)
			SetView(link_lyr)
			rec = LocateNearestRecord(location, 10)
			ShowMessage("2005 AT....."+string(link_lyr.AT_05))
		end
			
	enditem
    
    text "CBD" 6, 5.6
    text "Urban EEA" same, 7.2
    text "Urban" same, 8.8
    text "Suburban" same, 10.4
    text "Rural" same, 12.0
    
	button "Recalculate" 1, 16, 12.9, 1.5 do
		RunMacro("ComputeAT")
	enditem
    
	button "Process Ramps" same, after, 12.9, 1.5 do
		RunMacro("Process Ramps", link_lyr, node_lyr)
	enditem
        
    //EndMethod


	close do //StartMethod
		on NotFound goto next
		SetMapSaveFlag(map, "False")
		CloseMap(map)
        //CloseDbox("Area Type")
		next:
		on NotFound default
		
		Return()
	enditem //EndMethod

EndDbox  //End Area Type Model

Macro "CloseAT"

    on NotFound goto next
	CloseDbox("Area Type")
	next:
	on NotFound default
EndMacro



Macro "CalcLinkAT" (link_lyr, taz_lyr, InOpts)
    //Opts:
    //.LinkField: Field name on link layer
    //.ZoneField: Field name on taz layer
    //.Buffer: 0 for simple tag, or real value buffer in miles for dense AT tagging

    //Process options
    link_fld = InOpts.LinkField
    zone_fld = InOpts.ZoneField
    buffer = nz(InOpts.Buffer)
    Verbose = InOpts.Verbose
    
    //Get location of the taz layer (path to use for temp files)
    info = GetLayerInfo(taz_lyr)
    taz_file = info[10]
    pth = SplitPath(taz_file)
    pth = pth[1]+pth[2]
    
    //Clear all pre-existing values
    cnt = GetRecordCount(link_lyr,)
    SetDataVector(link_lyr+"|", "AREA_TYPE", Vector(cnt, "Long", ), )
    
    //Initially fill with tag
    TagLayer("Value", link_lyr+"|", link_lyr+"."+link_fld, taz_lyr, taz_lyr+"."+zone_fld)
    
    //Apply buffer if enabled
    if buffer > 0 then do
        
        //Get unique AT values
        AT2 = GetDataVector(taz_lyr+"|", zone_fld, )
        AT2 = SortVector(AT2, {{"Unique", "True"}, {"Omit Missing"}})
        
        //Reverse the sort and drop first (highest) value
        dim ATs[AT2.length - 1]
        for ii = 1 to (AT2.length - 1) do
            ATs[ii] = AT2[AT2.length + 1 - ii]
        end
        AT2 = null
        
        //Create a merged district layer
        dist_file = pth + "__TEMP__Districts_AT.dbd"
        dist_lyr = "District_AT"
        MergeByValue(dist_file,dist_lyr , taz_lyr+"|", zone_fld, "FFB", , )
        dist_lyr = AddLayer(GetMap(), dist_lyr, dist_file, dist_lyr, )
        
        //Select and fill each AT value, using the buffer
        for AT in ATs do
            //Select TAZs with this area type
            SetLayer(dist_lyr)
            SelectByQuery("AT", "Several", "Select * Where " + zone_fld + " = " + String(AT))
            
            //Create buffers
            buff_file = pth + "__TEMP__Buffers"+String(AT)+".dbd"
            buff_lyr = "Buffers_AT_"+String(AT)
            CreateBuffers(buff_file, buff_lyr, {"AT"}, "Value", {buffer}, {{"Units", "Miles"}})
            buff_lyr = AddLayer(GetMap(), buff_lyr, buff_file, buff_lyr, )
            
            //Select links within the buffer zone that have an AT value higher than the current value
            SetLayer(link_lyr)
            cnt = SelectByVicinity("ATL", "Several", buff_lyr+"|", 0, {{"Inclusion", "Enclosed"}})
            cnt = SelectByQuery("ATL", "Subset", "Select * Where AREA_TYPE > " + String(AT), {{"Inclusion", "Enclosed"}})
            
            //Fill the selected layers
            if cnt > 0 then SetDataVector(link_lyr+"|ATL", link_fld, Vector(cnt, "Integer", {{"Constant", AT}}), )
            
            DropLayer(GetMap(), buff_lyr)
            if !Verbose then DeleteDatabase(buff_file)
            
        end
        DropLayer(GetMap(), dist_lyr)
        if !Verbose then DeleteDatabase(dist_file)
    
    end
    
    //Set external connector and transit only links to AT=0
    SetView(link_lyr)
    cnt = SelectByQuery("AT0", "Several", "Select * Where NFC BETWEEN 81 and 98")
    SetDataVector(link_lyr+"|AT0", "AREA_TYPE", Vector(cnt, "Long", {{"Constant", 0}}), )
    
    //Set any remaining blank area type values to rural (5)
    cnt = SelectByQuery("AT0", "Several", "Select * Where AREA_TYPE = null")
    SetDataVector(link_lyr+"|AT0", "AREA_TYPE", Vector(cnt, "Long", {{"Constant", 5}}), )

EndMacro

Macro "Process Ramps" (link_lyr, node_lyr)

    //Select all ramps to be processed
    SetLayer(link_lyr)
    SelectByQuery("Ramps", "Several", 'Select * Where NFC_FLAG = "RON" or NFC_FLAG = "ROF" or NFC_FLAG = "RFF" or NFC_FLAG = "RFS" or NFC_FLAG = "RSF"', )
    
    //Create A and B node fields
    CreateNodeField(link_lyr, "AN", node_lyr+".ID", "From", )
    CreateNodeField(link_lyr, "BN", node_lyr+".ID", "To", )
    
    repeat = 1
    iters = 0
    //Repeat this process until nothing changes
    while repeat do
        repeat = 0
        
        //Load data into vectors
        R = GetDataVectors(link_lyr+"|Ramps", {"ID", "AREA_TYPE", "AN", "BN"}, {{"Return Options Array", "True"}})
        L = GetDataVectors(link_lyr+"|", {"ID", "AREA_TYPE", "AN", "BN"}, {{"Return Options Array", "True"}})
        
        //Check each ramp
        for II = 1 to R.ID.length do
            
            //Vector of area types on connected links
            ATV = if (L.AN=R.AN[II] or L.AN=R.BN[II] or L.BN=R.AN[II] or L.BN=R.BN[II]) then L.AREA_TYPE else null
            MinAT = VectorStatistic(ATV, "Min", )
            
            //Set AT to lower value if found in connected links
            // (Do not change to or from zero area type)
            if MinAT > 0 and R.AREA_TYPE[II] > 0 and MinAT < R.AREA_TYPE[II] then do
                repeat =  1
                R.AREA_TYPE[II] = MinAT
            end //if need to change
        end //II
        SetDataVector(link_lyr+"|Ramps", "AREA_TYPE", R.AREA_TYPE, )
        
        iters = iters + 1
    end //while repeat
    
    ShowMessage("Ran " + String(iters) + " times.")


EndMacro