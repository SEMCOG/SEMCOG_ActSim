// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//
//                             Custom TransCAD Scenario Manager 
//                  Adapted for use in the SEMCOG Regional Planning model
//
//                      Flexible and user friendly scenario management
//
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Self-contained UI dialog box, it is called from the model dialog box
//
// Input variables:
//	scen_num: The number of the scenario to act upon.  If scen_num is 0, create a new scenario. If scen_num is -1, copy the scenario
//  scenario_file: The scenario file to read from and write to.  If the file does not exist, scen_num is set to one and a new scenario is created.
//  new_scenario_dir: The scenario directory array - Always required but only used when creating a new scenario
//  newname: optional.  Used only if scen_num is 0.  This string will be used as the name for the new scenario.  Set To "New Scenario" if omitted.
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

Dbox "Scenario Manager" (scen_num, scenario_file, new_scenario_dir, newname) title: "Scenario Editor" Location: man_x, man_y, man_w, man_h resize
	//StartMethod - init
	init do
		static ADV_stat
        shared TimePeriods, CheckTimePeriods, PkTimePeriods, CheckPkTimePeriods
		shared Scen //scenario controller objects
        shared UT
		
		//Set up static location, overrides input location if available
		static man_x, man_y
        //(Leave location at default...)

		//Select input tab by default
		TabSelection = 1

		//look for a scenario array, create one if none exists
		if GetFileInfo(scenario_file) = null then do
			showmessage("No Scenarios Found.  \n" + "Creating Default Scenario ...")
			
			//Check for passed scenario name
			if newname = null then do
				if Scen.Vars.DefArgs.Info.Name = null then newname = "New Scenario"
				else newname = Scen.Vars.DefArgs.Info.Name
			end
		
			//Create a new scenario using the controller
			Args = Scen.Control.CreateScenario(Scen.Vars.DefArgs, new_scenario_dir)
			ScenArr = null
			ScenArr.(newname) = Args

			SaveArray(ScenArr, scenario_file)
			ScenArr = null
			scen_num = 1   //Set the active scenario to the first (and only) scenario
		end  //if no scen file exists

		//Add a new scenario if scen_num is 0 and a scenario file already exists
		else if scen_num = 0 then do

			//Load existing scenario array, get number of scenarios
			ScenArr = LoadArray(scenario_file)
			
			//Check for passed name, prevent duplicates by addiing (2), (3), etc.
			if newname = null then do
				if Scen.Vars.DefArgs.Info.Name = null then newname = "New Scenario"
				else newname = Scen.Vars.DefArgs.Info.Name
			end
			tempname = newname
			i = 2
			while ScenArr.(newname) do //while name already exists
				newname = tempname + " (" + string(i) + ")"
				i = i + 1
			end
			tempname = null

			//Create a new scenario using the controller
			Args = Scen.Control.CreateScenario(Scen.Vars.DefArgs, new_scenario_dir)
			ScenArr.(newname) = Args
			//Save the new scenario and retrieve the scenario number
			tmp = FindOption(ScenArr, newname)
			scen_num = tmp[1]
            Scen.Control.SEMCOG_SEDSwitch(Args)
			SaveArray(ScenArr, scenario_file)
			ScenArr = null
			DisableItem("Cancel")
		end  //if scen_num = 0 (Adding new scenario to existing list)
		
		//Copy the scenario if scen_num is -ve and a scenario file already exists
		else if scen_num < 0 then do
		
			copy_scen = -scen_num //Scenario to copy

			//Load existing scenario array, get number of scenarios
			ScenArr = LoadArray(scenario_file)
			copy_name = ScenArr[copy_scen][1]
			Args = CopyArray(ScenArr.(copy_name))
			
			//Check for passed name, prevent duplicates by addiing (2), (3), etc.
			if newname = null then newname = copy_name
			tempname = newname
			i = 2
			while ScenArr.(newname) do //while name already exists
				newname = tempname + " (" + string(i) + ")"
				i = i + 1
			end
			tempname = null
			if Args.Info.Name <> null then Args.Info.Name = newname

            //Set the created date/time
            Args.Info.DateCreated = GetDateAndTime()
            
			//Save the new scenario and retrieve the scenario number
			ScenArr.(newname) = Args
			tmp = FindOption(ScenArr, newname)
			scen_num = tmp[1]
			SaveArray(ScenArr, scenario_file)
			ScenArr = null
			DisableItem("Cancel")
		end  //if scen_num < 0 (Copying a scenario)

		//Load scenario array, set up easy-access pointers
		ScenArr = LoadArray(scenario_file)  //The entire scenario array
		_name = ScenArr[scen_num][1]
		Args = ScenArr.(_name)
		dbox_scenario_name = _name
		
		//Get scenario mode choice setting
		//ModeSetting is used to determine which files are required
		ModeSetting = Args.Param.MOD.Method.Value
		if ModeSetting = null then ModeSetting = "Choice" //Choice by default
		if ModeSetting = "Split" then ModeRadio = 1
		else ModeRadio = 2 //Choice by default
		
		//Show advanced if it is has been enabled during this TransCAD session
		//if ADV_stat = null then ADV_stat = 1  //Show by default
		if ADV_stat = 1 then do
			ShowItem("Advanced")
			ADVtext = "Hide Advanced"
		end
		else do
			ADVtext = "Show Advanced"
		end
		
		//Set up the feedback spinner
        FBText = String(Args.Param.ASN.FeedbackIters.Value)
        {Args.Param.ASN.FeedbackIters.Value, FBText, FBList} = UT.SpinnerList(S2I(FBText), 1, 1)
        if !Args.Param.ASN.RunFeedback.Value then do
            HideItem("Feedback Iterations")
            HideItem("Feedback Conv")
            HideItem("%")
        end else do
            ShowItem("Feedback Iterations")
            ShowItem("Feedback Conv")
            ShowItem("%")
        end
        
		StageNum = 1  //Set list to first stage
		_type = "Input"
		{FileArr, GridList} = Scen.Control.GetFiles( Args.(_type), _type, ModeSetting)  //Check file status
		
		//Set up grid column settings
		CellArr = {{1}, {1}}  //By default, select first file in list
		
		//Input grid columns
		dim InGrid_cols[3]
		InGrid_cols[1].Name = "ID"
		InGrid_cols[1].Width = 15
		InGrid_cols[1].Alignment = "Center"
		InGrid_cols[1].[Read Only] = True
		
		InGrid_cols[2].Name = "File Name"
		InGrid_cols[2].Width = 56.5
		InGrid_cols[2].Alignment = "Left"
		InGrid_cols[2].[Read Only] = True
		
		InGrid_cols[3].Name = "Status"
		InGrid_cols[3].Width = 20
		InGrid_cols[3].Alignment = "Left"
		InGrid_cols[3].[Read Only] = True
		
		dim StageGrid_cols[1]
		StageGrid_cols[1].Name = "Stage"
		StageGrid_cols[1].Width = 20
		StageGrid_cols[1].Alignment = "Center"
		StageGrid_cols[1].[Read Only] = True
		
		dim StageGridList[Scen.StageIndex.Length]
		for i = 1 to StageGridList.Length do
			StageGridList[i] = {Scen.StageIndex[i]}
		end
		
		//Output grid column settings
		dim OutGrid_cols[3]
		OutGrid_cols[1].Name = "ID"
		OutGrid_cols[1].Width = 15
		OutGrid_cols[1].Alignment = "Center"
		OutGrid_cols[1].[Read Only] = True

		OutGrid_cols[2].Name = "File Name"
		OutGrid_cols[2].Width = 55
		OutGrid_cols[2].Alignment = "Left"
		OutGrid_cols[2].[Read Only] = True

		OutGrid_cols[3].Name = "Status"
		OutGrid_cols[3].Width = 10
		OutGrid_cols[3].Alignment = "Left"
		OutGrid_cols[3].[Read Only] = True
		
		//Advanced grid column settings
		dim AdvGrid_cols[2]
		AdvGrid_cols[1].Name = "ID"
		AdvGrid_cols[1].Width = 15
		AdvGrid_cols[1].Alignment = "Center"
		AdvGrid_cols[1].[Read Only] = True

		AdvGrid_cols[2].Name = "Value"
		AdvGrid_cols[2].Width = 65
		AdvGrid_cols[2].Alignment = "Left"
		AdvGrid_cols[2].[Read Only] = False
		
		//Identify default clicked file
		_file = CellArr[1][1]
		_key = GridList[_file][1][1]

	enditem  //EndMethod - init

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// this sets up the format of the Scenario Manager
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// Scenario name and directory information

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//Text box with scenario name
	text "Scenario Name:" 1, 1
	edit text "Name" 15, 1, 35, 1 Variable: dbox_scenario_name resize: width

    
    button "Set Dir" 52, 1, 10, 1 help: "Set the output directory based on the UI location and scenario name" resize: left do 
    //StartMethod
        //Check scenario name
        forbidden = "/\:*?<>|"
        BadChar = False
        for i = 1 to Len(forbidden) do
            if Position(dbox_scenario_name, forbidden[i]) > 0 then do
                BadChar = True
            end
        end
        
        if BadChar then do
            ShowMessage("Cannot set output based on scenario name.\n\nThe following characters are not allowed: \/:*<>|")
            goto quitSetDir
        end
        
        //Determine new modle base directory
        t = SplitPath(GetInterface())
        ui_dir = t[1]+t[2]
        base_dir = ParseString(ui_dir, "\\")
        base_dir = ExcludeArrayElements(base_dir, base_dir.length, 1)
        base_dir = JoinStrings(base_dir, "\\") + "\\Model Runs\\" + dbox_scenario_name + "\\"

        old_in = Args.Info.[Input Directory]
        old_out = Args.Info.[Output Directory]

        new_in = base_dir + "Input\\"   
        new_out = base_dir + "Output\\"
        
        //Check for base directory existence
        if GetFileInfo(Left(base_dir, Len(base_dir)-1)) = null then do
            Opts = null
            Opts.Caption = "Create?"
            Opts.Buttons = "YesNo"
            Opts.Icon = "Question"
            Opts.Default = 1
            CreateNew = MessageBox("Base Scenario directory does not exist. Create?\n\n"+base_dir, Opts)
            if CreateNew then do
                CreateDirectory(Left(base_dir, Len(base_dir) - 1))
            end else do
                goto quitSetDir
            end
        end
        
        //Create Input and Output subdirectories if missing
        if GetFileInfo(Left(new_in, Len(new_in)-1)) = null then do
            CreateDirectory(Left(new_in, Len(new_in) - 1))
        end
        if GetFileInfo(Left(new_out, Len(new_out)-1)) = null then do
            CreateDirectory(Left(new_out, Len(new_out) - 1))
        end
            
        //Update Output Directory
        
        //Update scenario manager references
        Args.Info.[Input Directory] = new_in
        Args.Info.[Output Directory] = new_out
        
        //Put new directory on input filenames (if they have the %SCEN% key)
        for _file = 1 to Args.Input.Length do
            _key = Args.Input[_file][1]
            Args.Input.(_key).Value = Substitute(Args.Input.(_key).Value, old_in, new_in, )
        end

        //Put new directory on output filenames
        for _stage = 1 to Args.Output.Length do
            _stagekey = Args.Output[_stage][1]
            for _file = 1 to Args.Output.(_stagekey).Length do
                tmp = Args.Output.(_stagekey)
                _key = tmp[_file][1]
                Args.Output.(_stagekey).(_key).Value = Substitute(Args.Output.(_stagekey).(_key).Value, old_out, new_out, )
            end
        end
                
        //Update File List
        if _type = "Input" then {FileArr, GridList} = Scen.Control.GetFiles( Args.(_type), _type, ModeSetting)  //Check file status
        else if _type = "Output" then {FileArr, GridList} = Scen.Control.GetFiles( Args.(_type).(_stagekey), _type, ModeSetting)  //Check file status

        
        quitSetDir:
    enditem //EndMethod - Set output dir
    
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//StartMethod - Text box with input directory
	text "Input Dir:" 1, 3
	edit text "Dir" 15, 3, 73, 1 Variable: Args.Info.[Input Directory] Disabled resize: width
	button "Browse" 90, 3, 8, 1 resize: left do

		old_dir = Args.Info.[Input Directory]
		new_dir = RunMacro("Choose Dir", "Choose Scenario Directory:", old_dir)
		if new_dir <> null then do

			//Check to see if there is a trailing backslash, add if needed
			if right(new_dir, 1) <> "\\" then new_dir = new_dir + "\\"

			//Replace scenario directory in array
			Args.Info.[Input Directory] = new_dir

			//Put new directory on input filenames
            // (Don't modify any files with %SCEN% in the filename)
			for _file = 1 to Args.Input.Length do
				_key = Args.Input[_file][1]
				if Position(Scen.Vars.DefArgs.Input.(_key).Value, "%SCEN%") = 0 then
					Args.Input.(_key).Value = Substitute(Args.Input.(_key).Value, old_dir, new_dir, )

			end
				
			//Update File List
			if _type = "Input" then {FileArr, GridList} = Scen.Control.GetFiles( Args.(_type), _type, ModeSetting)  //Check file status
			else if _type = "Output" then {FileArr, GridList} = Scen.Control.GetFiles( Args.(_type).(_stagekey), _type, ModeSetting)  //Check file status

		end //if newdir is not canceled
	enditem //Chose input directory button
    //EndMethod - Input Directory

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//StartMethod - Text box with output directory

	text "Output Dir:" 1, 4.5
	edit text "Dir" 15, 4.5, 73, 1 Variable: Args.Info.[Output Directory] Disabled  resize: width
	button "Browse" 90, 4.5, 8, 1  resize: left do

		old_dir = Args.Info.[Output Directory]
		new_dir = RunMacro("Choose Dir", "Choose Scenario Directory:", old_dir)
		if new_dir <> null then do

			//Check to see if there is a trailing backslash, add if needed
			if right(new_dir, 1) <> "\\" then new_dir = new_dir + "\\"

			//Replace scenario directory in array
			Args.Info.[Output Directory] = new_dir

			//Put new directory on output filenames
			for _stage = 1 to Args.Output.Length do
				_stagekey = Args.Output[_stage][1]
				for _file = 1 to Args.Output.(_stagekey).Length do
					tmp = Args.Output.(_stagekey)
					_key = tmp[_file][1]
					Args.Output.(_stagekey).(_key).Value = Substitute(Args.Output.(_stagekey).(_key).Value, old_dir, new_dir, )
				end
			end
			
			//Put new directory on input filenames (if they have the %SCEN% key)
			for _file = 1 to Args.Input.Length do
				_key = Args.Input[_file][1]
				if Position(Scen.Vars.DefArgs.Input.(_key).Value, "%SCEN%") > 0 then do
					Args.Input.(_key).Value = Substitute(Args.Input.(_key).Value, old_dir, new_dir, )
				end
			end
			
			//Update File List
			if _type = "Input" then {FileArr, GridList} = Scen.Control.GetFiles( Args.(_type), _type, ModeSetting)  //Check file status
			else if _type = "Output" then {FileArr, GridList} = Scen.Control.GetFiles( Args.(_type).(_stagekey), _type, ModeSetting)  //Check file status

		end //if newdir is not canceled
	enditem //Chose output directory button
    //EndMethod - Output Directory
    
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//StartMethod - Save and Cancel buttons
	button "OK" 72, 27, 10, 2 Default resize: left, top do
		
		//Swap out scenario name (if needed)
		if dbox_scenario_name <> _name then do
			ScenArr[scen_num][1] = dbox_scenario_name
			Args.Info.Name = dbox_scenario_name
		end
		ScenArr.(dbox_scenario_name) = Args
		SaveArray(ScenArr, scenario_file)
		Return()
	endItem

	button "Cancel" 85, same, 10, 2 Cancel resize: left, top do
		Return()
	endItem

    //EndMethod - Save and Cancel Buttons
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Begin TAB list
	Tab List "ScenTabs" 1, 6, 98, 24 Variable: TabSelection resize: width, height

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//StartMethod - INPUT TAB
	Tab "Input" Prompt: "Input" do
		_type = "Input"
		CellArr = {{1}, {1}}  //Select first file in list
		//Update File List
		{FileArr, GridList} = Scen.Control.GetFiles( Args.(_type), _type, ModeSetting)
		
		//Identify clicked file
		_file = CellArr[1][1]
		_key = GridList[_file][1][1]
	enditem

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Scenario file scroll lists

	//Titles for file list
	
	Grid View "InputFileGrid" 2, 2, 95, 12 Multiple Columns: InGrid_cols List: GridList Variables: CellArr, ClickType resize: width, height do
    
        shared Scen
        ExpSets = Scen.ExpandSettings
	
		if CellArr <> null then do

			//Deal with users who click or double-click on the column header	
			//This will cause one entire column to be selected.  If the user double
			//clicks, this runs the code twice, requiring some annoyingly detailed
			//coding using the ClickedHeader variable.
			if CellArr[1] = null or (ClickedHeader and ClickType = 1) then do 
				CellArr = {{1}, {1,2,3}}
				if ClickType = 0 then ClickedHeader = True
				else ClickedHeader = False
			end
			else do 
			    ClickedHeader = False
				
				//Set CellArr to a single entire row
				CellArr = {{R2I(ArrayMax(CellArr[1]))}, {1}}
				
				//Identify clicked file
				_file = CellArr[1][1]
				_key = GridList[_file][1][1]
		
				if ClickType = 1 then do   //If the user double-clicked
					if FileArr[1] <> "<No Files>" then do
						tmp = SplitPath(FileArr[_file])
						new_file = RunMacro("GetSaveAs", {{"File", "*" + tmp[4]}}, "Choose Scenario File", tmp[1]+tmp[2], tmp[3]+tmp[4], "False")
						if new_file <> null then do
                        
                            //Check for %XXX% templates, substitute filename values with template (e.g., "AM" --> "%PER%")
                            for exp_kv in ExpSets do
                                {exp_k, exp_v} = exp_kv
                                tpl = "%"+exp_k+"%"
                                
                                if Position(Scen.Vars.DefArgs.Input.(_key).Value, tpl) > 0 then do
                                    for item in exp_v do
                                        t = SplitPath(new_file)
                                        if Position(t[3], item) > 0 then do
                                            t[3] = Substitute(t[3], item, tpl, 1)
                                            new_file = JoinStrings(t, )
                                            break //
                                        end
                                    end
                                    break //stop after one is found
                                end
                            end
                        
                            //Update filename in ARGS
                            Args.Input.(_key).Value = new_file
                        end
					end
				end
			end
		end
		//Update File List
		{FileArr, GridList} = Scen.Control.GetFiles( Args.(_type), _type, ModeSetting)
	enditem

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//File Description Box
	text "File Description:" 2, 15 resize: top
	edit text "Description" 2, 16.5, 65, 2 Variable: Args.Input.(_key).Desc resize: width, top Disabled
    
    //EndMethod -- Input Tab

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//StartMethod - GENERAL TAB
	Tab "General" Prompt: "General"

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//Scenario Description Box
	Frame 2, 2, 67, 5 Prompt: "Scenario Description" resize: width, height
	edit text "ScenDesc" 3, 3.5, 64, 3 Variable: Args.Info.Description resize: width, height
    
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//Assignment Settings
	checkbox "Run Speed Feedback" 5, 8 Variable: Args.Param.ASN.RunFeedback.Value resize: top, right do
		if Args.Param.ASN.RunFeedback.Value = 1 then do 
            ShowItem("Feedback Iterations")
            ShowItem("Feedback Conv")
            ShowItem("%")
            
		end else do
            HideItem("Feedback Iterations")
            HideItem("Feedback Conv")
            HideItem("%")
        end
	enditem
    
	spinner "Feedback Iterations" 15, 9.5 Prompt: "Iterations" List: FBList variable: FBText resize: top, right 
        help: "Set the number of speed feedback iterations" do  
		{Args.Param.ASN.FeedbackIters.Value, FBText, FBList} = UT.SpinnerList(S2I(FBText), 1, 1)
	enditem
    
    edit real "Feedback Conv" same, after Prompt: "Convergence" Variable: Args.Param.ASN.FeedbackConv.Value help: "Stop Feedback at an RMSE limit (0 to go to max iterations)" resize: top, right 
    text "%" after, same resize: top, right 

	//EndMethod -- General Tab

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//StartMethod - OUTPUT TAB
	Tab "Output" Prompt: "Output" do
		_type = "Output"
		CellArr = {{1}, {1}}  //Select first file in list
        if TypeOf(GridStage) != 'array' then do
            GridStage = {1, 1}  //Select first stage in list if not yet selected
        end
		_stage = GridStage[1]
		_stagekey = Scen.StageIndex[_stage]
		{FileArr, GridList} = Scen.Control.GetFiles( Args.(_type).(_stagekey), _type, ModeSetting)
		//Identify clicked file
        _file = CellArr[1][1]
        _key = GridList[_file][1][1]
	enditem

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Scenario file scroll lists

	Grid View "StageList" 2, 1.5, 9, 14 Columns: StageGrid_cols List: StageGridList Variable: GridStage resize: height do
		CellArr = {{1}, {1}}  //Select first file in list
		_stage = GridStage[1]
		_stagekey = Scen.StageIndex[_stage]
		//Update the file list
		{FileArr, GridList} = Scen.Control.GetFiles( Args.(_type).(_stagekey), _type, ModeSetting)
		//Identify clicked file
        if GridList <> null then do
            _file = CellArr[1][1]
            _key = GridList[_file][1][1]
        end
	enditem

	Grid View "OutputFileGrid" 13, 1.5, 82, 14 Multiple Columns: OutGrid_cols List: GridList Variables: CellArr, ClickType resize: width, height do
		if CellArr <> null then do
        
            shared Scen
            ExpSets = Scen.ExpandSettings
		
			//Deal with users who click or double-click on the column header	
			//This will cause one entire column to be selected.  If the user double
			//clicks, this runs the code twice, requiring some annoyingly detailed
			//coding using the ClickedHeader variable.
			if CellArr[1] = null or (ClickedHeader and ClickType = 1) then do 
				CellArr = {{1}, {1,2,3}}
				if ClickType = 0 then ClickedHeader = True
				else ClickedHeader = False
			end
			else do 
				ClickedHeader = False
		
				//Set to a CellArr to a single entire row
				if CellArr[1] = null then do 
					CellArr = {{1}, {1,2,3}}
					ClickType = 0
				end else if CellArr[2][1] = 3 then do
                    CellArr = {{R2I(ArrayMax(CellArr[1]))}, {3}}
				end else do
                    CellArr = {{R2I(ArrayMax(CellArr[1]))}, {1}}
                end
				
				//Identify clicked file
				_file = CellArr[1][1]
				_key = GridList[_file][1][1]
			
				if ClickType = 1 and FileArr[1] != "<No Files>" then do   //If the user double-clicked
					if CellArr[2][1] = 3 then do
                        allfiles = UT.Expand(FileArr[_file])
                        if TypeOf(allfiles) = 'array' then do
                            allfiles = UT.FlattenArray(allfiles)
                            for ii = 1 to allfiles.length do
                                if GetFileInfo(allfiles[ii]) = null then do
                                    allfiles[ii] = "MISSING - " + allfiles[ii]
                                end else do
                                    allfiles[ii] = "OK - " + allfiles[ii]
                                end
                            end
                            ShowArray(allfiles)
                        end
                        
                    end else do
						tmp = SplitPath(FileArr[_file])
						new_file = RunMacro("GetSaveAs", {{"File", "*" + tmp[4]}}, "Choose Scenario File", tmp[1]+tmp[2], tmp[3]+tmp[4], "False")
						if new_file <> null then do
                        
                            //Check for %XXX% templates, substitute filename values with template (e.g., "AM" --> "%PER%")
                            for exp_kv in ExpSets do
                                {exp_k, exp_v} = exp_kv
                                tpl = "%"+exp_k+"%"
                                
                                
                                if Position(Scen.Vars.DefArgs.Output.(_stagekey).(_key).Value, tpl) > 0 then do
                                    for item in exp_v do
                                        t = SplitPath(new_file)
                                        if Position(t[3], item) > 0 then do
                                            t[3] = Substitute(t[3], item, tpl, 1)
                                            new_file = JoinStrings(t, )
                                            break
                                        end
                                    end
                                end
                                
                            end
                        
                            //Update filename in ARGS
                            Args.Output.(_stagekey).(_key).Value = new_file
                        
                        end
					end
				end
			end
		end
		{FileArr, GridList} = Scen.Control.GetFiles( Args.(_type).(_stagekey), _type, ModeSetting)
	enditem 

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//File Description Box
	text "File Description:" 2, 16 resize: top
	edit text "Description" 2, 17.5, 65, 2 Variable: Args.Output.(_stagekey).(_key).Desc Disabled resize: top, width
	//EndMethod -- Output Tab
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// StartMethod - ADVANCED TAB
	Tab "Advanced" Prompt: "Parameters" do
		_type = "Param"
		CellArr = {1, 1}  //Select first file in list
		radlist = 2 //Default to parameters
        if TypeOf(GridStage) != 'array' then do
            GridStage = {1, 1}  //Select first stage in list if not yet selected
        end
        _stage = GridStage[1]
		_stagekey = Scen.StageIndex[_stage]
		if _type = "General" then {LineArr, GridList} = Scen.Control.GetAdv( Args.(_type), _type, ModeSetting)
		else {LineArr, GridList} = Scen.Control.GetAdv( Args.(_type).(_stagekey), _type, ModeSetting)
		
		//Identify clicked line
		_line = CellArr[1]
		_key = GridList[_line][1][1]
	enditem

	Grid View "StageListAdv" 2, 1.5, 9, 14 Columns: StageGrid_cols List: StageGridList Variable: GridStage resize: height do
		CellArr = {1, 1}  //Select first file in list
		_stage = GridStage[1]
		_stagekey = Scen.StageIndex[_stage]
		//Update the file list
		if _type = "General" then {LineArr, GridList} = Scen.Control.GetAdv( Args.(_type), _type, ModeSetting)
		else {LineArr, GridList} = Scen.Control.GetAdv( Args.(_type).(_stagekey), _type, ModeSetting)
		//Identify clicked line
		if GridList <> null then do
			_line = CellArr[1]
			_key = GridList[_line][1][1]
		end
	enditem
	
	Grid View "AdvancedGrid" 13, 3.5, 82, 11 Editable Columns: AdvGrid_cols List: GridList Variables: CellArr, ClickType help: "Click on a setting to see its description" resize: width, height do
		if CellArr <> null then do
		
			//Identify clicked line
			_line = CellArr[1]
			_key = GridList[_line][1][1]
		
			//If the user changes a value (and has not double-clicked in the header column)
			if ClickType = 1 and CellArr[2] = 2 then do
				if LineArr[1] <> "<No Files>" then do
					
					cell_val = GridList[CellArr[1]][CellArr[2]][1]
					
					//Edit an array with a recursive array editor
					if TypeOf(cell_val) = "string" and cell_val = "Edit..." then do
						if _type = "General" then NewVal = RunDbox("Edit Array", Args.(_type).(_key).Value)
						else NewVal = RunDbox("Edit Array", Args.(_type).(_stagekey).(_key).Value)
					end
                    else if TypeOf(cell_val) = "string" and cell_val = "Type Value..." then do
                        if _type = "General" then edit_sub = RunDbox("TextAnswer", "Enter Array or parameter value", Scen.IO.ArrayStringFull(Args.(_type).(_key).Value))
                        else edit_sub = RunDbox("TextAnswer", "Enter Array or parameter value", Scen.IO.ArrayStringFull(Args.(_type).(_stagekey).(_key).Value))
                        if TypeOf(edit_sub) = 'string' then edit_sub = Scen.IO.StrConv(edit_sub, )
                        if edit_sub <> null then do
                            NewVal = edit_sub
                        end
                        else do
                            if _type = "General" then NewVal = Args.(_type).(_key).Value
                            else NewVal = Args.(_type).(_stagekey).(_key).Value
                        end
                    end
                    else if TypeOf (cell_val) = "string" and (cell_val = "Set to null" or cell_val = "null") then do
                        if _type = "General" then Args.(_type).(_key).Value = null
                        else Args.(_type).(_stagekey).(_key).Value = null
                        NewVal = null
                    end
					
					//Or, update the value - convert typed numbers to numbers
					else if typeof(cell_val) = "string" then do
						edit_sub = Scen.IO.StrConv(cell_val, )
						if edit_sub <> null then do
							NewVal = edit_sub
						end
						else do
							if _type = "General" then NewVal = Args.(_type).(_key).Value
							else NewVal = Args.(_type).(_stagekey).(_key).Value
						end
					end
					
					//Or, just update the number
					else do
						NewVal = cell_val
					end
					if _type = "General" then do
                        if NewVal <> null then Args.(_type).(_key).Value = NewVal
                        if GridList[_line][2][1] = "null" then Args.(_type).(_key).Value = null
                    end else do
                        if NewVal <> null then Args.(_type).(_stagekey).(_key).Value = NewVal
                        if GridList[_line][2][1] = "null" then Args.(_type).(_stagekey).(_key).Value = null
                    end
				end

                if _type = "General" then {LineArr, GridList} = Scen.Control.GetAdv( Args.(_type), _type, ModeSetting)
                else {LineArr, GridList} = Scen.Control.GetAdv( Args.(_type).(_stagekey), _type, ModeSetting)
			end
            
            //Update SED for SEMCOG (must update when parameters are changed)
            Scen.Control.SEMCOG_SEDSwitch(Args)
			
		end //if CellArr <> null
	enditem 


	//!!! No general params for this modelradio list "Settings" 11, 1, 37, 2 Variable: radlist
	radio list "Settings" 11, 1, 25, 2 Variable: radlist
	Radio Button "Table" 13, 1.7, 7 help: "Adjust model tables (parameter arrays)" do
		_type = "Table"
		CellArr = {1, 1}  //Select first file in list
		{LineArr, GridList} = Scen.Control.GetAdv( Args.(_type).(_stagekey), _type, ModeSetting)
		//Identify clicked line
		if GridList <> null then do
			_line = CellArr[1]
			_key = GridList[_line][1][1]
		end
        ShowItem("StageListAdv")
	enditem
	Radio Button "Params" after, same, 9 help: "Adjust model parameters" do
		_type = "Param"
		CellArr = {1, 1}  //Select first file in list
		{LineArr, GridList} = Scen.Control.GetAdv( Args.(_type).(_stagekey), _type, ModeSetting)
		//Identify clicked line
		if GridList <> null then do
			_line = CellArr[1]
			_key = GridList[_line][1][1]
		end
        ShowItem("StageListAdv")
	enditem
	//!!! No general params for this model Radio Button "General" after, same, 9 help: "Set the general parameters" do
	//!!! No general params for this model 	_type = "General"
	//!!! No general params for this model 	CellArr = {1, 1}  //Select first file in list
	//!!! No general params for this model 	{LineArr, GridList} = Scen.Control.GetAdv( Args.(_type), _type, ModeSetting)
	//!!! No general params for this model 	//Identify clicked line
	//!!! No general params for this model 	if GridList <> null then do
	//!!! No general params for this model 		_line = CellArr[1]
	//!!! No general params for this model 		_key = GridList[_line][1][1]
	//!!! No general params for this model 	end
    //!!! No general params for this model     HideItem("StageListAdv")
	//!!! No general params for this model enditem
	
	button "Set To Defaults" 70, 16, 15, 1.5 help: "Set all values shown on this screen to defaults" resize: top, left do
		Args.(_type).(_stagekey) = CopyArray(Scen.Vars.DefArgs.(_type).(_stagekey))
		
		//Update the interface
		{LineArr, GridList} = Scen.Control.GetAdv( Args.(_type).(_stagekey), _type, ModeSetting)
	enditem
		
	
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//Param/Table Description Box
	text "Description:" 2, 16 resize: top
	edit text "Description" 2, 17.5, 65, 4 Variable: Args.(_type).(_stagekey).(_key).Desc Disabled resize: top, width
    
    //EndMethod -- Advanced Tab

EndDbox


// ****************************************************************************************************************
// Macro to change the scenario array file (defaults set by scenario_file in model defaults)
// ****************************************************************************************************************

Macro "Change Scenario File" (scenptr_file)
	shared scenario_file
	dir = SplitPath(scenario_file)
	dir = dir[1]+dir[2]
	new_scen_file = RunMacro("GetOpen", {{"Scenario File (*.arr)", "*.arr"}}, "Load Scenario File", dir)
	if new_scen_file = null then return()
	else do
		scenario_file = new_scen_file
		//ans = RunDbox("G30 Confirm", "Do you want to make this the default scenario list?")
		ans = "Yes"
		if ans = "Yes" then do
			fp = OpenFile(scenptr_file, "w")
			WriteArray(fp, {scenario_file})
			CloseFile(fp)
		end
	end
EndMacro

// ****************************************************************************************************************
// Macro to save the scenario array file to a different location (defaults set by scenario_file in model defaults)
// ****************************************************************************************************************

Macro "Save Scenario File" (scenptr_file)
	shared scenario_file
	dir = SplitPath(scenario_file)
	dir = dir[1]+dir[2]
	new_scen_file = RunMacro("GetSaveAs", {{"Scenario File (*.arr)", "*.arr"}}, "Save Scenario File", dir, , "True")
	if new_scen_file = null then return()
	
	CopyFile(scenario_file, new_scen_file)

	scenario_file = new_scen_file
	//ans = RunDbox("G30 Confirm", "Do you want to make this the default scenario list?")
	ans = "Yes"
	if ans = "Yes" then do
		fp = OpenFile(scenptr_file, "w")
		WriteArray(fp, {scenario_file})
		CloseFile(fp)
	end

EndMacro

// ****************************************************************************************************************
// Macro to create a new scenario array file (defaults set by scenario_file in model defaults)
// ****************************************************************************************************************

Macro "New Scenario File" (scenptr_file)
	shared scenario_file
	shared DefArgs
	shared scenario_dir
	dir = SplitPath(scenario_file)
	dir = dir[1]+dir[2]
	new_scen_file = RunMacro("GetSaveAs", {{"Scenario File (*.arr)", "*.arr"}}, "Create New Scenario File", dir, , "True")
	if new_scen_file = null then return()
	else do
		if GetFileInfo(new_scen_file) <> null then DeleteFile(new_scen_file)
		scenario_file = new_scen_file

		//ans = RunDbox("G30 Confirm", "Do you want to make this the default scenario list?")
		ans = "Yes"
		if ans = "Yes" then do
			fp = OpenFile(scenptr_file, "w")
			WriteArray(fp, {scenario_file})
			CloseFile(fp)
		end
		
		RunDbox("Scenario Manager", 0, scenario_file, scenario_dir)
	end
EndMacro

// ****************************************************************************************************************
// Dialog box to get equilibrium settings
// *************************************************************************************************

Dbox "Equilibrium Settings" (iter, gap, method, savepth)
	init do
		if method = 2 then ShowItem("Save Paths")
	enditem
	
	edit real 1, 1, 10, 1 Prompt: "Convergence"  Variable: gap
	edit real 1, 3, 5, 1 Prompt: "Iter. Limit"  Variable: iter
	
	checkbox "Save Paths" 1, 5, 15, 1 Variable: savepth hidden
	
	button "OK" 5, 7, 10, 1.5 do
		if gap <= 0 or gap >= 1 then do
			ShowMessage("Convergence criteria must be between zero and one!")
		end
		else if iter < 1 then do
			ShowMessage("Maximum iterations must be greater than zero!")
		end
		else do
			return({iter, gap, savepth})
		end
	enditem
	
	button "Cancel" 16, same, 10, 1.5 do
		return()
	enditem
EndDbox

// ****************************************************************************************************************
// Dialog box to select network and data year
// Arguments:
//   NetYear: Currently selected network year
//   DataYear: Currently selected data year
//   dbd_file: Geographic file name
//   mdb_file: Database File
//   avail_tname: Name of Access Database table specifying available data years
//
// Opts: Optional options array
//   Opts.HideNetwork:  If True, don't ask for the network year (defaults to false)
//   Opts.HideData:     If True, don't ask for the data year (defaults to false)
//   Opts.YearFields:   If present, verify that data is present for all included fields (link only)
// ****************************************************************************************************************
Dbox "Set Years" (NetYear, DataYear, dbd_file, mdb_file, avail_tname, InOpts) title: "Scenario Settings"
	init do
		shared MdbTables, INI_IDX
		
		//Check option to check for network years
		if InOpts.YearFields <> null and TypeOf(InOpts.YearFields) = "array" then do
			YearFields = CopyArray(InOpts.YearFields)
		end
		else do
			YearFields = null
		end
		
		//Verify that required files are present
		if InOpts.HideNetwork = True and InOpts.HideData = True then do
			ShowMessage("Cannot hide both data and network questions.")
			Return()
		end
		else if InOpts.HideNetwork = False and InOpts.HideData = False then do
			if GetFileInfo(dbd_file) = null | GetFileInfo(mdb_file) = null then do
				ShowMessage("Cannot set scenarios unless both geographic and database files are defined and present.")
				Return()
			end
		end 
		else if InOpts.HideNetwork = False then do  //just show network question
			if GetFileInfo(dbd_file) = null then do
				ShowMessage("Cannot set network scenario unless geographic file is defined and present.")
				Return()
			end
		end
		else do  //Just show data question
			if GetFileInfo(mdb_file) = null then do
				ShowMessage("Cannot set data scenario unless geographic file is defined and present.")
				Return()
			end
		end
		
       	//Open the geographic network
		if InOpts.HideNetwork = False then do
    		RunMacro("TCB Add DB Layers", dbd_file,,)
    		Lyrs = RunMacro("TCB get DB line and node layers", dbd_file)
    		node_lyr = Lyrs[1]
    		link_lyr = Lyrs[2]
			
			//Get the list of potential alternatives
			
			
			//Get available network years
			Fields = GetFields(link_lyr, "Integer")
			Fields = Fields[1]
			PotYearList = null
			for i = 1 to Fields.length do
				left_f = left(Fields[i], 3)
				right_f= substring(Fields[i], 4, )
				if left_f = "FT_" and len(right_f) >= 1 and len(right_f) <= 4 then PotYearList = PotYearList + {right_f}
			end
			
			//If no years are present...	
			if PotYearList = null then do
				ShowMessage("No scenarios found in current network")
				Return()
			end
			
			//Check validity of potential years
			NetYearList = null
			for i = 1 to PotYearList.length do
				Check = RunMacro("Check NetYear", PotYearList[i], link_lyr, YearFields)
				if Check = PotYearList[i] then do
					NetYearList = NetYearList + {Check}
				end
			end
			
			//Close the network
			on error goto nodrop
			DropLayerFromWorkspace(link_lyr)
			DropLayerFromWorkspace(node_lyr)
			nodrop:
			on error default
			
            //Sort the list
			NetYearList = SortArray(NetYearList)
			
			//Determine current index
			NetInd = ArrayPosition(NetYearList, {NetYear}, )
			
			//Set to the first item in the list if not found
			if NetInd = 0 then NetInd = 1
			
			ShowItem("Network Year")
		end //end getting year data
		
		
		if InOpts.HideData = False then do
			//Open the model database
			dsn_name = RunMacro("CreateDSN", mdb_file)
			avail_vw = OpenTable(avail_tname, "ODBC", {dsn_name, avail_tname, , })
			
			DataYearList = GetRecordsValues(avail_vw+"|", GetFirstRecord(avail_vw+"|", ), {"AvailYear"}, , GetRecordCount(avail_vw, ), "Column", )
			DataYearList = DataYearList[1]
			
			//Close the model database
			CloseView(avail_vw)
			
			//Sort the list
			DataYearList = SortArray(DataYearList)
			
			//Determine current index
			DataInd = ArrayPosition(DataYearList, {DataYear}, )
			
			//Set to the first item in the list if not found
			if DataInd = 0 then DataInd = 1
			
			ShowItem("Data Year")
		end //end getting data year
		
		
	enditem
	
	//Dialog Box Items:
	popdown menu "Network Year" 10, 1   prompt: "Network" List: NetYearList Variable: NetInd hidden
	popdown menu "Data Year"    10, 3   prompt: "Data"    List: DataYearList Variable: DataInd hidden
	
	Button "OK" 15, 6, 10, 1.5 do
		if InOpts.HideNetwork = False then ret_year = NetYearList[NetInd]
		else ret_year = null
		if InOpts.HideData = False then ret_data = DataYearList[DataInd]
		else ret_data = null
		
		Return({ret_year, ret_data})
	enditem
	
	Button "Cancel" 26.5, 6, 10, 1.5 do
		Return()
	enditem


EndDbox

// ****************************************************************************************************************
// Macro to check the network modelyear against the current network
// ****************************************************************************************************************
    
Macro "Check NetYear" (NetYear, link_lyr, YearFields)

    //Verify the year is not set to "AL"
    if NetYear = "AL" then Return(null)
    
    //Check for the following fields
    Fields = CopyArray(YearFields)
    for i = 1 to Fields.length do
        Fields[i][1] = Fields[i][1] + "_" + NetYear
    end
    
    //Check for required fields
    on notfound do
		ShowMessage("NETWORK FORMAT WARNING:\n\nFT data present for year \""+NetYear+"\"\nField Not Found: " + Fields[i][1])
		goto quit
	end
    for i = 1 to Fields.Length do
        GetFieldInfo(link_lyr + "." + Fields[i][1])
    end
    on notfound default
    
    //On success:
    Return(NetYear)
    
    //On failure:
    quit:
    on notfound default
    Return(null)
EndMacro

// ****************************************************************************************************************
// Dialog box to select network alternatives
// ****************************************************************************************************************

Dbox "Set Network Alts" (NetAlts, dbd_file)
	title: "Select Network Alternatives"
    init do
        //Check forgeographic file
        if GetFileInfo(dbd_file) = null then do
            ShowMessage("Please Select a geographic file before choosing alternatives.")
            Return(null)
        end

        //Open the geographic network
	    RunMacro("TCB Add DB Layers", dbd_file,,)
	    Lyrs = RunMacro("TCB get DB line and node layers", dbd_file)
	    node_lyr = Lyrs[1]
	    link_lyr = Lyrs[2]
        
        //Get a list of alternatives
        SetView(link_lyr)
        SelectByQuery("Alts", "Several", "Select * Where ALT > 0", )
        ALTS = GetDataVector(link_lyr + "|Alts", "ALT", )
        Ualts = RunMacro("Unique Values", ALTS)
        
        //Separate selected and non-selected alts
        OutAlts = null
        InAlts  = null
        for i = 1 to Ualts.Length do
            if ArrayPosition(NetAlts, {Ualts[i]}, ) = 0 then
                OutAlts = OutAlts + {Ualts[i]}
            else
                InAlts = InAlts + {Ualts[i]}
        end
        if OutAlts = null then OutAlts = {}
        
    enditem
    
    text "AltInfo" 1, 1, 20, 1 variable: "Available Alternatives" framed
    Scroll List "NotAlts" 1, 2.5, 20, 15 Multiple List: OutAlts Variable: OutIndex
    
    button ">>" 24, 5, 3, 1.5 Help: "Add All" do
        OutIndex = null
        for i = 1 to OutAlts.length do
            OutIndex = OutIndex + {i}
        end
        {OutAlts, InAlts} = RunMacro("Move Selected", OutAlts, InAlts, OutIndex)
        DisableItem(">>")
        DisableItem(">")
        EnableItem("<<")
        EnableItem("<")
        OutIndex = null
    enditem    
    button ">" 24, 7, 3, 1.5 Help: "Add Selected" do
        if OutIndex <> null then do
            {OutAlts, InAlts} = RunMacro("Move Selected", OutAlts, InAlts, OutIndex)
            if OutIndex <> null then do
                if ArrayMax(OutIndex) > OutAlts.Length then do
                    if OutAlts.Length = 0 then OutIndex = null
                    else if OutAlts.Length > 0 then OutIndex = {OutAlts.Length}
                end
                if OutIndex.Length > 1 then OutIndex = null
            end
            if OutAlts = null then do
                DisableItem(">")
                DisableItem(">>")
            end
            Enableitem("<<")
            EnableItem("<")
        end
    enditem
    
    button "<" 24, 11, 3, 1.5 Help: "Remove Selected" do
        if InIndex <> null then do
            {InAlts, OutAlts} = RunMacro("Move Selected", InAlts, OutAlts, InIndex)
            if InIndex <> null then do
                if ArrayMax(InIndex) > InAlts.Length then do
                    if InAlts.Legnth = 0 then InIndex = null
                    else if InAlts.Length > 0 then InIndex = {InAlts.Length}
                end
                if InIndex.Length > 1 then InIndex = null
            end
            if InAlts = null then do
                DisableItem("<")
                DisableItem("<<")
            end
            Enableitem(">>")
            EnableItem(">")
        end
    enditem
    button "<<" 24, 13, 3, 1.5 Help: "Remove All" do
        InIndex = null
        for i = 1 to InAlts.length do
            InIndex = InIndex + {i}
        end
        {InAlts, OutAlts} = RunMacro("Move Selected", InAlts, OutAlts, InIndex)
        DisableItem("<<")
        DisableItem("<")
        EnableItem(">>")
        EnableItem(">")
        InIndex = null
    enditem
    
	text "AltInfo" 30, 1, 20, 1 variable: "Active Alternatives" framed
    Scroll List "NotAlts" 30, 2.5, 20, 15 Multiple List: InAlts Variable: InIndex

    button "OK" 30, 19, 9, 1 default do
        if InAlts = null then InAlts = {}
        Return(InAlts)
    enditem
    button "Cancel" 40, 19, 9, 1 cancel do
        Return()
    enditem
    
EndDbox

// ****************************************************************************************************************
// Additional usefull macros
// ****************************************************************************************************************

Macro "Choose Dir" (prompt, init_dir)

		on escape goto canceled
		if right(init_dir, 1) = "\\" then
			init_dir = left(init_dir, StringLength(init_dir) - 1)
		ret_dir = ChooseDirectory(prompt, {{"Initial Directory", init_dir}})
		return(ret_dir)

		canceled:
		return(null)

EndMacro

Macro "GetSaveAs" (f_type, title, init_dir, init_name, warn)
        //f_type: {{"Type Name", "*.xxx"}, {xetc,etc}}
		//title: Window Title
		//warn: "True" or "False - warn overwrite
	Opts = {{"Initial Directory",     init_dir},
	        {"Suggested Name",        init_name},
			{"Replace Warning",       warn}}

	on escape goto cancel
		newname = ChooseFileName(f_type, title, Opts)
	on escape default

	return(newname)

	cancel:
	return(null)
EndMacro

// ****************************************************************************************************************
// Macro to find out if a selection in a scroll list is contiguous
// Returns "True" or "False"
Macro "Check Selection" (SelArr)
	if SelArr.length = 1 then Return("True")

	for i = 2 to SelArr.Length do
		if SelArr[i] <> SelArr[i-1] + 1 then Return("False")
	end

	Return("True")
EndMacro

// ****************************************************************************************************************
// Macro to move a selection up or down in a scroll list
// Arr = Scroll list (or other) array
//       - Can be an array or any type
// SelArr = array of selected indices
//          - must be shorter than Arr
//          - Must contain selected items in ascending order --> unpredictable results otherwise
//          - Selection must be contiguous (returns original Arr otherwise)
// Dir = "Up" or "Down"
//Returns: {Modified Array, Modified selection}
Macro "Move Selection" (Arr, SelArr, Dir)

	//Check for contiguity of selection
	if RunMacro("Check Selection", SelArr) = "False" then Return({Arr, SelArr})
	//See if the entire array is selected
	if SelArr.Length >= Arr.length then Return({Arr, SelArr})

	//identify direction
	if Dir = "Up" then do
		if SelArr[1] = 1 then Return({Arr, SelArr})  //If already in front
		else if SelArr[1] = 2 then         //If moving to the front of the list

			RetArr =  SubArray(Arr, SelArr[1], SelArr.Length) +        //Selected block
			          {Arr[1]} +                                       //item now directly after selected block
					  SubArray(Arr, SelArr[SelArr.length] + 1, null)   //remaining items
		else
			RetArr =  SubArray(Arr, 1, SelArr[1] - 2) +                //Items still before selected block
			          SubArray(Arr, SelArr[1], SelArr.Length) +        //Selected block
					  {Arr[SelArr[1] - 1]} +                           //Item now directly after selected block
					  SubArray(Arr, SelArr[SelArr.length] + 1, null)   //remaining items
        dim RetSelArr[SelArr.length]
		for i = 1 to SelArr.length do
			RetSelArr[i] = SelArr[i] - 1
		end
	end
	else if Dir = "Down" then do
		if SelArr[SelArr.length] = Arr.Length then Return({Arr, SelArr})  //If already at the end
		else if SelArr[SelArr.Length] = Arr.Length - 1 then     //If moving to the end of the list

			RetArr =  SubArray(Arr, 1, SelArr[1]-1) +                  //Items before selected block
			          {Arr[SelArr[SelArr.length]+1]} +                 //item now directly before selected block
					  SubArray(Arr, SelArr[1], SelArr.Length)          //Selected block
		else
			RetArr =  SubArray(Arr, 1, SelArr[1]-1) +                  //Items before selected block
			          {Arr[SelArr[SelArr.length] + 1]} +               //item now directly before selected block
					  SubArray(Arr, SelArr[1], SelArr.Length) +        //Selected block
					  SubArray(Arr, SelArr[SelArr.length] + 2, null)   //Items now directly after selected block

		dim RetSelArr[SelArr.length]
		for i = 1 to SelArr.length do
			RetSelArr[i] = SelArr[i] + 1
		end
	end
	else do
		RetArr = CopyArray(Arr)
	    RetSelArr = CopyArray(NewSelArr)
	end
	Return({RetArr, RetSelArr})

EndMacro

Macro "GetOpen" (ftype, title, init_dir)
	//File Type is: {{"Type Name", "*.ext"}}

	if right(init_dir, 1) = "\\" then  //remove trailing backslash
		init_dir = left(init_dir, StringLength(init_dir) - 1)
	Opts = {{"Initial Directory",     init_dir}}

	on escape goto cancel
		newname = ChooseFile(ftype, title, Opts)
	on escape default

	return(newname)

	cancel:
	return(null)
EndMacro

Macro "Unique Values" (Arr)
    if Arr.Length < 1 then return()
    RetArr = {Arr[1]}
    for i = 2 to Arr.Length do
        if ArrayPosition(RetArr, {Arr[i]}, ) = 0 then
            RetArr = RetArr + {Arr[i]}
    end
    Return(RetArr)
EndMacro

Macro "Move Selected" (List1, List2, Ind) //Moves selected from L1 to L2 - for use with the alternative selection dialog
    //Add to L2
    for i = 1 to Ind.length do
        List2 = List2 + {List1[Ind[i]]}
    end
    //Remove L1
    NewL1 = null
    for i = 1 to List1.Length do
        if ArrayPosition(Ind, {i}, ) = 0 then
            NewL1 = NewL1 + {List1[i]}
    end
    List1 = CopyArray(NewL1)
    
    List1 = SortArray(List1)
    List2 = SortArray(List2)
    
    Return({List1, List2})
EndMacro


//Class to control scenario manager dialog boxes
// - CreateScen: Creates a new scenario array (in particular - deals with path names from an Default Args array)
// - ImportINI: Imports an INI file into the scenario array
// - CheckScen: Verifies the integrity of a scenario - adjusts automatically if needed
// - CheckFiles: Checks file stepwise file status and returns array of avaialble and unavailable steps
// - GetFiles: Checks file status and returns an array formatted for the scenario manager grid
// - GetAdv: Loads tables/parameters/dbTables and returns an array formatted for the scenario manager grid
// - SubSteps: Open the SubSteps dialog box
// - AllSteps: Open the AllSteps dialog box
Class "Scen.Control"
//StartClass

	init do //StartMethod
	
        shared Scen

		//If the file called ScenarioFilename.txt exists in the same directory as the ui file,
		//use this file to identify a scenario array.
		if GetFileInfo(Scen.Vars.scenptr_file) <> null then do
			fp = OpenFile(Scen.Vars.scenptr_file, "r")
			tmp = ReadArray(fp)
			CloseFile(fp)
			tmp = tmp[1]
			if GetFileInfo(tmp) <> null then do
				Scen.Vars.scenario_file = tmp
			end
		end

	EndItem //EndMethod - init
	
    Macro "UpdateList" do
        //Update scenario list if scenario file exists
		shared Scen
        
        //If no scenario file exists, call manager to create one
        if GetFileInfo(Scen.Vars.scenario_file) = null then do
            RunDbox("Scenario Manager", 1, Scen.Vars.scenario_file, Scen.Vars.scenario_dir)
        end
        //else do
            //Load the scenario file
            Scen.Arr = LoadArray(Scen.Vars.scenario_file)
			
			//Check scenario file for compatibility
			for _scen = 1 to Scen.Arr.length do
				_scenname = Scen.Arr[_scen][1]
				//Correct internal name in older scenario files - can be deleted once all scenario files are up to date (but is not harful to leave in)
				if _scenname <> Scen.Arr.(_scenname).Info.Name then Scen.Arr.(_scenname).Info.Name = _scenname  
				//This line scrubs the scenario list and ensures that all scenarios are consistent with the default scenario structure
				//This line is run each time the scenario list is updated, and is therefore applied to imported scenarios.
				tmp = self.CheckScen(Scen.Vars.DefArgs, Scen.Arr.(_scenname), {{"SkipItems", {"Choice"}}})  
                self.SEMCOG_SEDSwitch(tmp)
				
				if TypeOf(tmp) <> "array" and tmp = -1 then ShowMessage("Error: Invalid Scenario File!\n * Scenario \""+_scenname+"\" is invalid *")
				else Scen.Arr.(_scenname) = tmp
			end
			//Save updated scenario array
			SaveArray(Scen.Arr, Scen.Vars.scenario_file)
            
            //set up sample items
            colors = RunMacro("G30 setup colors")
            init_sample = SamplePoint("Font Character", "Caliper Cartographic|10", 37, ColorRGB(0, 0, 0), Opts)
            missing_sample = SamplePoint("Font Character", "Caliper Industry|10", 104, colors[5], Opts)
            ready_sample = SamplePoint("Font Character", "Caliper Cartographic|13", 36, colors[25], Opts)
            partial_sample = SamplePoint("Font Character", "Caliper Miscellaneous|10", 58, colors[7], Opts)
            done_sample = SamplePoint("Font Character", "Wingdings 2|Bold|14", 80, colors[25], Opts)

            //Get Scenario Names
            dim NameList[Scen.Arr.length]
			dim tmp[Scen.Arr.length]
            if Scen.Vars.ScrNameList != null then do
                PrevList = CopyArray(Scen.Vars.ScrNameList)
            end
            Scen.Vars.ScrNameList = CopyArray(tmp)  //For scroll list
            for ii = 1 to Scen.Arr.length do
                NameList[ii] = Scen.Arr[ii][1]
                
                if PrevList != null and ii <= PrevList.length then do
                    samp = PrevList[ii][1][3]
                end else do
                    samp = init_sample
                end
                
                Scen.Vars.ScrNameList[ii] = {{0, "L", samp}, 
                                            {5, "L", Scen.Arr[ii][1]}}
                
            end

            if (Scen.Vars.ScenFlag.length = 1 | Scen.Vars.ScenFlag = null) then do  //For a single scenario

                //Make sure scenflag is valid, if too long null or zero - select last scenario
                if Scen.Vars.ScenFlag = null or TypeOf(Scen.Vars.ScenFlag) <> "array" then
                    Scen.Vars.ScenFlag = {Scen.Arr.length}
				if Scen.Vars.ScenFlag[1] = 0 then
					Scen.Vars.ScenFlag = {Scen.Arr.length}
                if Scen.Vars.ScenFlag[1] > Scen.Arr.length then
                    Scen.Vars.ScenFlag = {Scen.Arr.length}

                //Update arrays based on scenario file
                Scen.Vars.scenario_name = NameList[Scen.Vars.ScenFlag[1]]
                Scen.Vars.scenario_dir = {Scen.Arr.(Scen.Vars.scenario_name).Info.[Input Directory], 
				                                  Scen.Arr.(Scen.Vars.scenario_name).Info.[Output Directory]}
                Scen.Vars.scenario_desc = Scen.Arr.(Scen.Vars.scenario_name).Info.[Description]
				
				//Enable the copy button
                Scen.Buttons.Copy = "Enable"

            end //if one is selected
            else do

                //Make sure scenflag is valid, if too long - select last scenario
                if arraymax(Scen.Vars.ScenFlag) > Scen.Arr.length or ArrayMin(Scen.Vars.ScenFlag) < 1 then
                    Scen.Vars.ScenFlag = {Scen.Arr.length}
				if Scen.Vars.ScenFlag.Lengh > Scen.Arr.length then
					Scen.Vars.ScenFlag = {Scen.Arr.length}

                //If more than one are selected, list must already be loaded
                Scen.Vars.scenario_name = "--Multiple--"
                Scen.Vars.scenario_desc = "--Multiple--"
				Scen.Vars.scenario_dir = {"--Multiple--", "--Multiple--"}

                //Disable the Copy button
                Scen.Buttons.Copy = "Disable"

            end  //end if more than one is selected

			//Set status of delete button (can't delete the last scenario)
            if Scen.Arr.length = 1 or Scen.Arr.Length = Scen.Vars.ScenFlag.Length then Scen.Buttons.Delete = "Disable"
            else Scen.Buttons.Delete = "Enable"

			//Set status of move up and down buttons
			if RunMacro("Check Selection", Scen.Vars.ScenFlag) = "False" or Scen.Vars.ScenFlag.Length = Scen.Vars.ScrNameList.Length then do
                Scen.Buttons.[Move Up] = "Disable"
                Scen.Buttons.[Move Down] = "Disable"
			end
			else do
                Scen.Buttons.[Move Up] = "Enable"
                Scen.Buttons.[Move Down] = "Enable"
			end

            //Check files
            
            CheckLimit = Scen.Vars.CheckLimit
            //Check all if no limit, or limit higer than total
            if CheckLimit = null or CheckLimit > (Scen.Arr.length) then do
                dim check_scens[Scen.Arr.length]
                for ii = 1 to check_scens.length do
                    check_scens[ii] = ii
                end
            end else do
                //Only check last n scenarios
                StartCheck = Scen.Arr.length - CheckLimit
                dim check_scens[CheckLimit]
                for ii = 1 to check_scens.length do
                    check_scens[ii] = ii + StartCheck
                end
                
                //Plus, any selected
                for ii = 1 to Scen.Vars.ScenFlag.length do
                    _scen = Scen.Vars.ScenFlag[ii]
                    if ArrayPosition(check_scens, {_scen}, ) = 0 then do
                        check_scens = check_scens + {_scen}
                    end
                end
                
            end

            for _scen in check_scens do
            
                in_ok = 1
                out_ok = 1
                out_some = 0
                mismatch = 0
                
                _name = Scen.Arr[_scen][1]
                
                //Determine mode choice setting
                ModeSetting =  Scen.Arr.(_name).Param.MOD.Method.Value
                if ModeSetting = null then ModeSetting = "Choice" //Choice by default
                
                //Check input files
                for _input = 1 to Scen.Arr.(_name).Input.length do
                
                    _key = Scen.Arr.(_name).Input[_input][1]
                    _keydata = Scen.Arr.(_name).Input.(_key)
                    
                    if !self.CheckFile(_keydata.Value) then do
                        req = _keydata.(ModeSetting)
                        if req = "Required" or req = null then do
                            in_ok = 0
                            _input = Scen.Arr.(_name).Input.length  //stop checking input
                        end
                    end
                end //end looping over _input
                //Done checking input files
                
                //Check output files
                for _stage = 1 to Scen.Arr.(_name).Output.length do
                    _stagekey = Scen.Arr.(_name).Output[_stage][1]
                    for _output = 1 to Scen.Arr.(_name).Output.(_stagekey).length do
                        tmp = Scen.Arr.(_name).Output.(_stagekey)
                        _key = tmp[_output][1]
                        _keydata = Scen.Arr.(_name).Output.(_stagekey).(_key)
                        
                        if !self.CheckFile(_keydata.Value) then do
                            req = _keydata.(ModeSetting)
                            if req = "Required" or req = null then do
                                out_ok = 0
                            end
                        end
                        else out_some = True
                    end //loop over files
                end //loop over stages
                //Done checking output files

                //Show the appropriate status for this scenario:
                if in_ok & out_ok then
                    Scen.Vars.ScrNameList[_scen][1][3] = done_sample
                else if in_ok & out_some then
                    Scen.Vars.ScrNameList[_scen][1][3] = partial_sample
                else if in_ok then
                    Scen.Vars.ScrNameList[_scen][1][3] = ready_sample
                else
                    Scen.Vars.ScrNameList[_scen][1][3] = missing_sample
                    
            end //end looping over scenarios
		
        //Update project box (only if scenario dbox has been created in full)
        if scenario_dbox then do
            if Scen.Vars.ScenFlag.length = 1 then
                RetScenArr = Scen.Arr[Scen.Vars.ScenFlag[1]]
            else RetScenArr = null
            SetAlternateInterface(model_ui)
            UpdateDbox(main_box)
            SetAlternateInterface()
        end
    enditem //EndMethod - UpdateList
    
    Macro "CheckFile" (filepath, PartialOK) do
        //Check file presence - allowing for %% placeholders
        shared Scen, UT
        
        //Check simple files w/o templates
        if Position(filepath, "%") = 0 then do
            if GetFileInfo(filepath) = null then Return(null)
            else Return(1)
        end
    
        //Check files with templates (%XXX% placeholder)
        allfiles = UT.Expand(filepath)
        if TypeOf(allfiles) != 'array' then Return()
        allfiles = UT.FlattenArray(allfiles)
        
        
        for ii = 1 to allfiles.length do
            nfo = GetFileInfo(allfiles[ii])
            if !PartialOK and nfo = null then Return(0)  //Fail if not partial and at least one file missing
            else if PartialOK and nfo != null then Return(1) //OK if at least one partial file present
        end
        Return(1)
        
        /*
        ExpSets = Scen.ExpandSettings
        
        for exp_kv in ExpSets do
            fname = filepath
            {exp_k, exp_v} = exp_kv
            tpl = "%"+exp_k+"%"
            if Position(filepath, tpl) > 0 then do
                ok = True
                for item in exp_v do
                    if GetFileInfo(Substitute(filepath, tpl, item,)) = null then do
                        ok = False
                        break
                    end
                end
                if ok then Return(1)
                else Return(null)
            end
        end //exp_kv
        */

                
    enditem //EndMethod
    
    // *************************************************************************
    // Macro to check for available files and disable some buttons if needed
    Macro "CheckFiles" do  //Run on dbox update
        shared Scen
        
        step_count = Scen.StageNames.Length
    
        dim FileCheck[step_count] //1 if input files are missing
        dim OutCheck[step_count]

        //Check all selected scenarios
        for i = 1 to Scen.Vars.ScenFlag.length do

            //Update information for current scenario
            scenario_name = Scen.Arr[Scen.Vars.ScenFlag[i]][1]
            Args = Scen.Arr.(scenario_name)
            
            //Mode Split setting
            ModeSetting = "Choice" //Must be "Choice" (left over from legacy split/choice option)

            //Check input files
            IDX = 1 //Input files are required to run stage 1
            for _input = 1 to Args.Input.length do
            
                _key = Args.Input[_input][1]
                _keydata = Args.Input.(_key)
                
                //if GetFileInfo(_keydata.Value) = null then do
                if !self.CheckFile(_keydata.Value) then do
                    req = _keydata.(ModeSetting)
                    if req = "Required" or req = null then FileCheck[IDX] = 1
                   end
            end //end looping over _input
            //Done checking input files

            //Check output files
            for _stage = 1 to Args.Output.length do
                _stagekey = Args.Output[_stage][1]
                for _output = 1 to Args.Output.(_stagekey).length do
                    tmp = Args.Output.(_stagekey)
                    _key = tmp[_output][1]
                    _keydata = Args.Output.(_stagekey).(_key)
                    
                    //if GetFileInfo(_keydata.Value) = null then do
                    if !self.CheckFile(_keydata.Value) then do
                        req = _keydata.(ModeSetting)
                        if req = "Required" or req = null then do
                            IDX = ArrayPosition(Scen.StageIndex, {_stagekey}, )
                            OutCheck[IDX] = 1  //lookup the missing stage using StageIndex
                        end
                     end
                end //loop over files
            end //loop over stages
            //Done checking output files
            
        end //end looping over all selected scenarios

        //Determine how many stages have been successfully run for all scenarios
        StopFlag = null
        for i = 1 to OutCheck.length do
            if OutCheck[i] = 1 then do
                StopFlag = i + 1
                goto EndOutCheck  //break the loop
            end
        end
        EndOutCheck:

        //Enable stages - based on completed stages, only if all input files exist
        dim StepStatus[step_count] //all disabled by default
        if FileCheck[1] != 1 then do
            CheckCheck = 0
            for i = 1 to step_count do
                if StopFlag = null or i < StopFlag then do
                    StepStatus[i] = True
                end

            end //setting buttons
        end
        
        if StopFlag = null and !FileCheck[1] then do
            RunComplete = True
        end else do
            RunComplete = False
        end
        
        if !FileCheck[1] then do
            RunReady = True
        end else do
            RunReady = False
        end
        
        /*
        //Only allow performance if not stopping after each stage
        if StopStage = 0 then EnableItem("Perf")
        if StopStage = 1 then do
            CreatePerf = 0
            DisableItem("Perf")
        end
        
        //Enable/Disable input utility buttons
        //Disable If missing any input files -OR- more than one selected
        if !debug and (FileCheck[1] or ScenFlag.length <> 1) then do
            DisableItem("Edit Network Year")
            DisableItem("Create Select Query")
            DisableItem("Copy Feedback Results")
            DisableItem("Conformity Export")
            DisableItem("Edit Network")
        end
        else do
            EnableItem("Edit Network Year")
            EnableItem("Create Select Query")
            EnableItem("Copy Feedback Results")
            EnableItem("Conformity Export")
            EnableItem("Edit Network")
        end
        
        //Enable/Disable Maps and Reports buttons
        
        //Disable if any selected scenario is not complete (allow multiple)
        if debug or (ScenFlag.Length = 1 and !FileCheck[1] and StopFlag = null) then do
            EnableItem("Summary Report")
            EnableItem("Create Maps")
        end
        else do
            DisableItem("Summary Report")
            DisableItem("Create Maps")
        end
        
        //Disable if any selected scenario is not complete (allow multiple)
        if debug or (ScenFlag.Length = 2 and !FileCheck[1] and StopFlag = null) then do
            EnableItem("Ozone Export")
        end
        else do
            DisableItem("Ozone Export")
        end
        
        */
        
        Return({'StepStatus':StepStatus, 'RunComplete':RunComplete, 'RunReady':RunReady})
        
    EndItem     //macro to check files
    //EndMethod

	Macro "Manage" do
		//Show the scenario manager dialog box
		shared Scen
		RunDbox("Scenario Manager", Scen.Vars.ScenFlag[1], Scen.Vars.scenario_file, Scen.Vars.scenario_dir)
	enditem //EndMethod - Manage
	
	Macro "AddScen" do
		//Show the scenario manager dialog box
		shared Scen
		RunDbox("Scenario Manager", 0, Scen.Vars.scenario_file, Scen.Vars.scenario_dir)
	enditem //EndMethod - Manage
	
	Macro "CopySelected" do
		//Show the scenario manager dialog box
		shared Scen
		if Scen.Vars.ScenFlag.length != 1 then do
			Throw("Only one scenario can be copied at a time")
		end
		//-ve scenario number requests that a copy is made
		RunDbox("Scenario Manager", -Scen.Vars.ScenFlag[1], Scen.Vars.scenario_file, Scen.Vars.scenario_dir)
	enditem //EndMethod - Manage
	
	Macro "DeleteSelected" do
		shared Scen
		
        if Scen.Arr.length = 1 or Scen.Arr.length = Scen.Vars.ScenFlag.length then
            Throw("Cannot Delete Last Remaining Scenario")
		
		tmparray = CopyArray(Scen.Arr)
		for i = 1 to Scen.Vars.ScenFlag.Length do
			tmp = FindOption(tmparray, Scen.Arr[Scen.Vars.ScenFlag[i]][1])
			DeleteNo = tmp[1]
			tmparray = ExcludeArrayElements(tmparray, DeleteNo, 1)
		end
		
		Scen.Arr = CopyArray(tmparray)
		SaveArray(Scen.Arr, Scen.Vars.scenario_file)
	
	enditem //EndMethod
	
	Macro "MoveSelection" (Dir) do
		shared Scen, model_ui
		Dir = Proper(Dir)
		if Dir != "Up" and Dir != "Down" then Throw("Error - Invalid direction argument to MoveSelection")
		
		{Scen.Arr, NewScenFlag} = RunMacro("Move Selection", Scen.Arr, Scen.Vars.ScenFlag, Dir)
		{Scen.Vars.ScrNameList, } = RunMacro("Move Selection", Scen.Vars.ScrNameList, Scen.Vars.ScenFlag, Dir)
		
		Scen.Vars.ScenFlag = CopyArray(NewScenFlag)
        SaveArray(Scen.Arr, Scen.Vars.scenario_file)
	
	
	enditem	//EndMethod
	
    Macro "RunModel" (StartStage) do
        
        shared Scen, UT, canned, model_ui
        
        //Hide the calling dbox
        HideBox = CreateObject("HideBox", model_ui, Scen.Vars.[Model Name] + " Model")
        
        //Get the original log and report files, note that the model is starting
        LogManager = CreateObject("LogManager")
        ColName = {{"Bold", "True"}, {"Percentage Width", 20}}
        ColStat = {{"Bold", "False"}}
        
        AppendToReportFile(0, "Starting "+ Scen.Vars.[Model Name] +" Batch", {{"Section", "True"}})
        AppendTableToReportFile({ColName, ColStat}, {{"Title", "Number of Scenarios: "+String(Scen.Vars.ScenFlag.length)}, {"Indent", 2}})
        AppendRowToReportFile({"Start Time:", UT.FormatDate()}, )
        CloseReportFileSection()
        
        AppendToLogFile   (0, "Starting Procedure "+ Scen.Vars.[Model Name] +" on " + UT.FormatDate() + ".", {{"Section", "True"}})
        AppendToLogFile   (2, "Running " + String(Scen.Vars.ScenFlag.length) + " scenarios.")
        
        //Run for each scenario
        for _scen = 1 to Scen.Vars.ScenFlag.length do
            scen = Scen.Vars.ScenFlag[_scen]
        
            //Set current scenario
            Scen.Vars.scenario_name = Scen.Arr[scen][1]
            Args = Scen.Arr[scen][2]
            Scen.Vars.scenario_dir = {Args.Info.[Input Directory], 
                                      Args.Info.[Output Directory]}
            
            //Verify all output directories exist
            for stage in Scen.StageIndex do
                UT.CreateOutputDirs(Args.Output.(stage))
            end
            
            //Stage settings
            EndStage = if Scen.StopStage then StartStage else Scen.StageNames.length
            
            //Simplify Args if running a model using the simplified Caliper Args style
            if Scen.Vars.Simplified then do
                UseArgs = self.Simplified(Args)
            end else do 
                UseArgs = CopyArray(Args)
            end
            
            //Feedback settings
            Scen.Feedback.run = UseArgs.RunFeedback
            Scen.Feedback.iters = UseArgs.FeedbackIters
            Scen.Feedback.converged = False
            
            //Check to see if speed feedback can be run.
            //Set Scen.Feedback.run to False if any stage is not set to run.
            if StartStage != 1 then Scen.Feedback.run = 0
            if EndStage != Scen.StageNames.length then Scen.Feedback.run = 0
            if Scen.Feedback.run then do
                for _stage = StartStage to EndStage do
                    for _step = 1 to Scen.StepSwitch[_stage].length do
                        if !Scen.StepSwitch[_stage][_step] then do
                            Scen.Feedback.run = 0
                        end
                    end //_step
                end //_stage
            end
            
            if !Scen.Feedback.run then do 
                Scen.Feedback.iters = 1
            end
            
            
            //Set the scenario run date
            Args.Info.Date = GetDateAndTime()
            
            
            //Set summary report date string
            file_date = UT.FormatDate(Args.Info.Date, {{"Sortable", True}})
            
            //Update main log and report files
            scenario_rpt = Scen.Vars.scenario_dir[2] + file_date + " Report.xml"
            scenario_log = Scen.Vars.scenario_dir[2] + file_date + " Log.xml"
            LogManager.Reset()
            AppendToReportFile(0, "Starting "+ Scen.Vars.[Model Name] +" Scenario", {{"Section", "True"}})
            AppendTableToReportFile({ColName, ColStat}, {{"Title", "Model Run Information"}, {"Indent", 2}})
            AppendRowToReportFile({"Scenario Name:", Scen.Vars.scenario_name}, )
            AppendRowToReportFile({"Start Time:", UT.FormatDate(Args.Info.Date)}, )
            AppendRowToReportFile({"Report File:", scenario_rpt}, )
            AppendRowToReportFile({"Log File:", scenario_log}, )
            CloseReportFileSection()
            
            AppendToLogFile   (2, "Running Scenario: " + Scen.Vars.scenario_name)

			//Set the report and log file
			SetReportFileName(scenario_rpt)
			SetLogFileName(scenario_log)
			ResetReportFile()
			ResetLogFile()
			
			AppendToReportFile(0, "Starting "+ Scen.Vars.[Model Name], {{"Section", "True"}})
			ColName = {{"Bold", "True"}, {"Percentage Width", 20}} //{{"Name", "Name"}}
			ColStat = {{"Bold", "False"}} //{{"Name", "Status"}}
			AppendTableToReportFile({ColName, ColStat}, {{"Title", "Model Run Information"}, {"Indent", 2}})
            AppendRowToReportFile({"Scenario Name:", Scen.Vars.scenario_name}, )
            start_time = UT.FormatDate()
			AppendRowToReportFile({"Start Time:", start_time}, )
			DestroyStopwatch("Scen.ModelTime")
			CreateStopwatch("Scen.ModelTime")
            AppendRowToReportFile({"First Step:", Scen.StageNames[StartStage]}, )
			AppendRowToReportFile({"Stop After Each Step:", if Scen.StopStage then "Yes" else "No"}, )
			AppendRowToReportFile({"Feedback:", if Scen.Feedback.run then "Yes" else "No"}, )
            if (UseArgs.RunFeedback & !Scen.Feedback.run) then do
                AppendRowToReportFile({" ", "* Feedback Disabled for partial model run."}, )
            end            
			AppendRowToReportFile({"Create Report:", if Scen.CreatePerf then "Yes" else "No"}, )
            
            CloseReportFileSection()
            
            //Create text tracking report
            status_file = Scen.Vars.scenario_dir[2]+file_date + " RunStatus.txt"
            sp = OpenFile(status_file, 'w')
            WriteLine(sp, '**** SEMCOG Regional Travel Model - Run Status ****')
            WriteLine(sp,)
            WriteLine(sp,'* Starting Model Run' )
            WriteLine(sp,'    Scenario Name: '+Scen.Vars.scenario_name)
            WriteLine(sp,'    Start Time: '+start_time)
            WriteLine(sp,'    Feedback: ' + if Scen.Feedback.run then 'Enabled' else 'Disabled')
            CloseFile(sp)
            
            //Create a progress bar 
            ProgTitle = "Running Scenario " + i2s(_scen) + " of " + i2s(Scen.Vars.ScenFlag.Length) + ": " + Scen.Vars.scenario_name
            SetProgressWindow(ProgTitle, 4)
            
            //Run the model macros for this scenario

            //BatchTimer = {{"Stage Name", StageTime, {{"StepName", StepTime}, ..., {"StepName", StepTime}}}, ...}            
            BatchTimer = null
            
            RunMacro("TCB Init")
            if Scen.Feedback.run then do
                CreateProgressBar("Feedback Loop 1 of " + String(Scen.Feedback.iters), "True")
            end
            
            for _fb = 1 to Scen.Feedback.iters do
                Scen.Feedback.iteration = _fb //The Scen.Feedback.iteration variable cannot serve as the loop iterator (compile error)
                if Scen.Feedback.run then do
                    canned = UpdateProgressBar("Feedback Loop " + String(Scen.Feedback.iteration) + " of " + String(Scen.Feedback.iters), R2I(Scen.Feedback.iteration / Scen.Feedback.iters * 100))
                    if canned then goto stop
                    
                    sp = OpenFile(status_file, 'a')
                    WriteLine(sp,)
                    WriteLine(sp, UT.FormatDate() + '* Starting Feedback Loop ' + String(Scen.Feedback.iteration) + ' of ' + String(Scen.Feedback.iters))
                    
                end
                
                for _stage = StartStage to EndStage do
                    SetProgressWindow(ProgTitle, 4) //Re-setting each stage to correct for some odd behavior
                    CreateProgressBar(Scen.StepMacro[_stage][1], "True")
                    
                    sp = OpenFile(status_file, 'a')
                    WriteLine(sp,UT.FormatDate() + '  * Starting Stage ' + Scen.StepMacro[_stage][1])
                    CloseFile(sp)
                
                    //Time the stage
                    DestroyStopwatch("Scen.StageTimer")
                    CreateStopwatch("Scen.StageTimer")
                    StepTimer = null
                
                    for _step = 1 to Scen.StepSwitch[_stage].length do
                    
                        //Check to see if the step should be run
                        run_step = Scen.StepSwitch[_stage][_step]
                        
                        //Loop-specific run checks
                        if Scen.Feedback.run then do
                            fb_flag = Scen.StepFeedback[_stage][_step]
                            
                            //Skip flag 0 if not on first loop
                            if fb_flag = 0 and Scen.Feedback.iteration != 1 then run_step = False
                            
                            //Skip flag 2 on all but last run or after convergence
                            if fb_flag = 2 and Scen.Feedback.iteration != Scen.Feedback.iters and !Scen.Feedback.converged then run_step = False
                            
                        end
                    
                        if run_step then do
                        
                            //Timer and progress bar
                            DestroyStopwatch("Scen.StepTimer")
                            CreateStopwatch("Scen.StepTimer")
                            canned = UpdateProgressBar(Scen.StepMacro[_stage][_step], Scen.StepProg[_stage][_step])
                            if canned then goto stop
                            
                            sp = OpenFile(status_file, 'a')
                            WriteLine(sp,UT.FormatDate() + '    * Starting Step ' + Scen.StepMacro[_stage][_step])
                            CloseFile(sp)
                        
                            //Run the step
                            SetAlternateInterface(model_ui)
                            ret_value = RunMacro(Scen.StepMacro[_stage][_step], UseArgs)
                            SetAlternateInterface()
                           
                            // TEST: Looping and error reporting
                            /*
                            Pause(50)
                            ret_value = 1
                            //if Scen.Feedback.iteration = 3 then Scen.Feedback.converged = True
                            //if _stage > 2 and _step > 2 then ret_value = 0
                            */
                            
                            //Record time
                            step_time = CheckStopwatch("Scen.StepTimer")
                            StepTimer = StepTimer + {{Scen.StepMacro[_stage][_step], UT.FormatTime(step_time)}}
                            DestroyStopwatch("Scen.StepTimer")
                            
                            sp = OpenFile(status_file, 'a')
                            WriteLine(sp,UT.FormatDate() + '      > Step Complete.')
                            WriteLine(sp,UT.FormatDate() + '      > Run Time: ' + UT.FormatTime(step_time))
                            CloseFile(sp)
                            
                            if !ret_value then break
                        end //enabled
                    end //_step
                    
                    //Record stage time
                    stage_time = CheckStopwatch("Scen.StageTimer")
                    DestroyStopwatch("Scen.StageTimer")
                    BatchStageName = Scen.StageNames[_stage]
                    
                    if Scen.Feedback.run then do
                        BatchStageName = "Feedback Iteration " + String(Scen.Feedback.iteration) + " - " + BatchStageName
                    end
                    
                    BatchTimer = BatchTimer + {{BatchStageName, UT.FormatTime(stage_time), StepTimer}}
                    
                    sp = OpenFile(status_file, 'a')
                    WriteLine(sp,UT.FormatDate() + '    > Stage Complete.')
                    WriteLine(sp,UT.FormatDate() + '    > Run Time: ' + UT.FormatTime(stage_time))
                    CloseFile(sp)
                    
                    if !ret_value then goto stop
                    
                    on NotFound do 
                        goto NoProgToCancel
                    end
                    DestroyProgressBar()
                    NoProgToCancel:
                    on NotFound default
                    ResetProgressWindow()
                end //_stage
                
                //Run final loop if feedback converged
                if Scen.Feedback.converged then do
                    break
                end
                
            end //feedback
            
            //Create the summary report if enabled
            if Scen.CreatePerf then do
            
                sp = OpenFile(status_file, 'a')
                WriteLine(sp,UT.FormatDate() + '  * Creating Summary Report')
                CloseFile(sp)
            
                DestroyStopwatch("Scen.ReportTimer")
                CreateStopwatch("Scen.ReportTimer")
            
                Scen.Perf.SetArgs(UseArgs)
                Scen.Perf.Args2 = CopyArray(Args)
                
                ret_value = Scen.Perf.CreateReport()
                if !ret_value then goto stop
                
                report_time = CheckStopwatch("Scen.ReportTimer")
                DestroyStopwatch("Scen.ReportTimer")
                
                StepTimer = {{"Create Report", UT.FormatTime(report_time)}}
                BatchTimer = BatchTimer + {{"Summary Report", UT.FormatTime(report_time), StepTimer}}
                
                sp = OpenFile(status_file, 'a')
                WriteLine(sp,UT.FormatDate() + '    > Summary Report Complete.')
                WriteLine(sp,UT.FormatDate() + '    > Run Time: ' + UT.FormatTime(report_time))
                CloseFile(sp)
            
            end
            
            //Destroy the progress bar
            if Scen.Feedback.run then do
                    on NotFound do 
                        goto NoFBProgToCancel
                    end
                    DestroyProgressBar()
                    NoFBProgToCancel:
                    on NotFound default
            end
            ResetProgressWindow()
            
            //Get Elapsed Time
            tot_time = CheckStopwatch("Scen.ModelTime")
            DestroyStopwatch("Scen.ModelTime")
            run_time = UT.FormatTime(tot_time)
            
            //Write to the report file
            RunMacro("TCB Closing", ret_value, "False")
            AppendToReportFile(0, "Model Run Completed", {{"Section", "True"}})
            
            
            /*
            AppendTableToReportFile({ColName, ColStat}, {{"Title", "Scenario: "+Scen.Vars.scenario_name}, {"Indent", 2}})
            */
            
            sp = OpenFile(status_file, 'a')
            WriteLine(sp,)
            WriteLine(sp,'> Model Run Complete.')
            WriteLine(sp,'    End Time: ' + UT.FormatDate())
            WriteLine(sp,'    Run Time: ' + run_time)
            CloseFile(sp)
            
            ColStage = {}
            ColStep = {}
            ColTime = {}
            AppendTableToReportFile({ColName, ColStat}, {{"Title", "Model Run Time Information"}, {"Indent", 2}})
            AppendRowToReportFile({"Scenario Name:", Scen.Vars.scenario_name}, )
            AppendRowToReportFile({"Start Time:", start_time}, )
            AppendRowToReportFile({"End Time:", UT.FormatDate()}, )
            AppendRowToReportFile({"Total Run Time:", run_time}, )
            
            AppendTableToReportFile({ColName}, {{"Title", "Run Time by Step"}, {"Indent", 2}})
            for _stage = 1 to BatchTimer.length do
                AppendTableToReportFile({ColName+{{"Name", BatchTimer[_stage][1]}}, ColStat+{{"Name", BatchTimer[_stage][2]}}}, {{"Indent", 3}})
                for _step = 1 to BatchTimer[_stage][3].length do
                    AppendRowToReportFile({BatchTimer[_stage][3][_step][1], BatchTimer[_stage][3][_step][2]}, )
                end //_step
            end //_stage
            
            
            CloseReportFileSection()
            
        end //loop over scenarios
        
        
        Opts = null
        Opts.Caption = "Complete"
        Opts.Buttons = "YesNo"
        Opts.Default = 2
        Opts.Modal = "Appl"
        ans = MessageBox("Success!  Model Run Complete.\nDo you want to show the batch report?", Opts)
        if ans = "Yes" then LaunchDocument(scenario_rpt, )
            
        //Close the batch processor, inform the user if an error occurred.
        stop:
        if !ret_value then do
        
            //Get Elapsed Time
            tot_time = CheckStopwatch("Scen.ModelTime")
            DestroyStopwatch("Scen.ModelTime")
            run_time = UT.FormatTime(tot_time)
            
            //RunMacro("Lose")
            
            if canned then do 
                msg = "The run was canceled during model macro " + Scen.StepMacro[_stage][_step] + ".\n" +
                        "Model Run Terminated. Do you want to show the log and report?"
            end else do
                msg = "An error occurred in model macro " + Scen.StepMacro[_stage][_step] + ".\n" +
                        "Model Run Terminated. Do you want to show the log and report?"
            end
            
            RunMacro("TCB Closing", ret_value, "False")
            
            //Write to the report file
            AppendTableToReportFile({ColName, ColStat}, {{"Title", "Model Run Time Information"}, {"Indent", 2}})
            AppendRowToReportFile({"Scenario Name:", Scen.Vars.scenario_name}, )
            AppendRowToReportFile({"Start Time:", start_time}, )
            AppendRowToReportFile({"End Time:", UT.FormatDate()}, )
            AppendRowToReportFile({"Total Run Time:", run_time}, )
            
            AppendTableToReportFile({ColName}, {{"Title", "Run Time by Step"}, {"Indent", 2}})
            for _stage = 1 to BatchTimer.length do
                AppendTableToReportFile({ColName+{{"Name", BatchTimer[_stage][1]}}, ColStat+{{"Name", BatchTimer[_stage][2]}}}, {{"Indent", 3}})
                for _step = 1 to BatchTimer[_stage][3].length do
                    AppendRowToReportFile({BatchTimer[_stage][3][_step][1], BatchTimer[_stage][3][_step][2]}, )
                end //_step
            end //_stage
            
            CloseReportFileSection()
            
            Opts = null
            Opts.Caption = "Error"
            Opts.Buttons = "YesNo"
            Opts.Icon = "Stop"
            Opts.Default = 1
            Opts.Modal = "Appl"
            ans = MessageBox(msg, Opts)
            msg = null
            if ans = "Yes" then do 
                LaunchDocument(scenario_rpt, )
                LaunchDocument(scenario_log, )
                LaunchDocument(LogManager.OrigReport, )
                LaunchDocument(LogManager.OrigLog, )
            end

        end //if !ret_val (error occurred)

        //Reset the report file
        LogManager = null
        AppendToLogFile(2, "Done running the "+ Scen.Vars.[Model Name] +" model.")
        
        HideBox = null //Show the dialog box tht was hidden

        UT.KillBars()  //Remove any remaining progress bars (if an error occurred)
    
    EndItem //EndStep - Run Model
    
    Macro "PackScen" (Args, fname) do
        //Pack a single scenario
        shared Scen, UT, canned, model_ui, ui_dir
    
        z_pgm = ui_dir + "7z\\7za"
    
        //Check for assignment and network output directories
        out_dir = Args.Info.[Output Directory] + "Output\\"
        asn_dir = out_dir + "Assignment"
        net_dir = out_dir + "Network"
        if GetFileInfo(asn_dir) = null or GetFileInfo(net_dir) = null then 
            Throw("Cannot pack scenario " + scenario_name + ".\nMissing required directory")
        asn_dir = asn_dir + "\\"
        net_dir = net_dir + "\\"
        
        //Delete old archive if present
        if GetFileInfo(fname) != null then DeleteFile(fname)
        
        //Pack the data
        cmd = z_pgm + ' a -t7z  "' + fname + '" ' + net_dir
        RunProgram(cmd, )
        cmd = z_pgm + ' a -t7z  "' + fname + '" ' + asn_dir
        RunProgram(cmd, )
        
    enditem //EndMethod - PackScen
    
    Macro "PackMulti" do
        //Pack all selected scenarios
        shared Scen
        
        for _scen = 1 to Scen.Vars.ScenFlag.length do
            scen = Scen.Vars.ScenFlag[_scen]
        
            //Set current scenario
            Scen.Vars.scenario_name = Scen.Arr[scen][1]
            Args = Scen.Arr[scen][2]
            
            fname = Args.Info.[Output Directory] + Scen.Arr[scen][1] + ".7z"
            
            self.PackScen(Args, fname)
        end
            
        
    enditem //EndMethod - PackMulti
    
	Macro "CreateScenario" (DefArgs, scenario_dir) do
//CreateScen: Crease a scenario array using the input and output directories
// scenario_dir = {InputDir, OutputDir}
	
		shared Scen
		
		if scenario_dir = null then do
			scenario_dir = {DefArgs.Info.[Input Directory], 
                            DefArgs.Info.[Output Directory]}
		end

		//Start with the default
		Args = CopyArray(DefArgs)
		
		//Set directories - allows use of relative subdirectories
		Args.Info.[Input Directory] = scenario_dir[1]
		Args.Info.[Output Directory] = scenario_dir[2]
		
		//Input
    	for _input = 1 to Args.Input.length do
			_key = Args.Input[_input][1]
            if Position(Args.Input.(_key).Value, "%SCEN%\\") > 0 then do //Use the output directory for files with %SCEN% in the default path
                tmp_value = Substitute(Args.Input.(_key).Value, "%SCEN%\\", "", )
                Args.Input.(_key).Value = Scen.IO.GetFullPath(tmp_value, scenario_dir[2])
            end
            else Args.Input.(_key).Value = Scen.IO.GetFullPath(Args.Input.(_key).Value, scenario_dir[1])
		end //end looping over _input
		
		//Output
		for _stage = 1 to Args.Output.Length do
			_stagekey = Args.Output[_stage][1]
			for _output = 1 to Args.Output.(_stagekey).length do
			    tmp = Args.Output.(_stagekey)
				_key = tmp[_output][1]
				Args.Output.(_stagekey).(_key).Value = Scen.IO.GetFullPath(Args.Output.(_stagekey).(_key).Value, scenario_dir[2])
			end //end looping over _output
		end //end looping over output _stages
		//Done adding directory information
		
		//Set date and time
		Args.Info.DateCreated = GetDateAndTime()
        Args.Info.Description = "New Scenario"
		
		//Return the new scenario array
		Return(Args)
	
	EndItem
	//EndMethod
	
	Macro "ImportINI" (scenario_file) do
	
		//Access the IO object, which is part of the main Scen object.
		shared Scen
	
		//Ask the user for the INI file locaion
		import_file = RunMacro("GetOpen", {{"Scenario INI File (*.INI)", "*.ini"}}, "Select Scenario to Import", ) // Directory memory ???
		if import_file = null then Return()
		
		//Load the complete scenario array
		ScenArr = LoadArray(scenario_file)
		
		//Read the INI file
		import_args = Scen.IO.ReadINI(import_file, True, )
		if import_args = null then Return() //Invalid INI file
		import_name = import_args.Info.Name
		if import_name = null then import_name = "Imported Scenario"
		
		//Check for name duplication
		i = 2
		tempname = import_name
		while ScenArr.(import_name) do //while name already exists
			import_name = tempname + " (" + string(i) + ")"
			i = i + 1
		end
		tempname = null
		import_args.Info.Name = import_name
		
		//Create the new scenario (This applies the input and output paths to relative filenames)
		Args = self.CreateScenario(import_args, )  //Use the scenario name in the INI file
		
		//Add the new scenario to the scenario file array
		ScenArr.(import_name) = Args
		SaveArray(ScenArr, scenario_file)
		
		//Return the imported scenario number (list ID number)
		tmp = FindOption(ScenArr, import_name)  //Get the location of the imported scenario...
		tmp = tmp[1]
		Return(tmp)
	
	enditem
	//EndMethod
	
	Macro "ExportINI" (Args) do
	
		shared Scen, defscen_file
		
		//Ask the user for the INI save location
		export_file = RunMacro("GetSaveAs", {{"Scenario INI File (*.INI)", "*.ini"}}, "Export Scenario To...", null, null, "True") // Directory memory ???
		if export_file = null then Return()
		
		//Run the export 
		Scen.IO.WriteINI(export_file, Args, defscen_file)
	
	enditem
	//EndMethod
	
	Macro "CheckScen" (DefArgs, Args, Opts) do
	//Macro to check an Args array against a DefArgs array
	//Returns an updated Args array if changes were necessary, a copy of the original if no changes were required
	//   --> Note - the array will be sorted like the DefArgs array.
	// - If the Args array has extra options, they are removed.
	// - If the Args array has missing options, they are added.
	// - If the Args array is missing a required Info option, a -1 is returned
	//   --> Added files are added into the appropriate input/output directory using relative path names.
	//
	// DefArgs: Default arguments array
	// Args: Scenario array to check
	// Opts:
	//  Opts.SkipItems = Optional array of key values to replace with default values on import
	
		shared Scen
		
		//Check for the Value Only Option - Process into a simple variable
		if Opts.SkipItems <> null then SkipItems = CopyArray(Opts.SkipItems)
	
		//Info items are required:
		if Args.Info.Name = null then Return(-1)
		if Args.Info.[Input Directory] = null then Return(-1)
		if Args.Info.[Output Directory] = null then Return(-1)
        
		ModArgs = null
        //Allow any additional info items
        for item in Args.Info do
            ModArgs.Info.(item[1]) = item[2]
        end
        
		//Check for trailing backslash on directories
		ModArgs.Info.[Input Directory] = Scen.IO.DirFormat(ModArgs.Info.[Input Directory])
		ModArgs.Info.[Output Directory] = Scen.IO.DirFormat(ModArgs.Info.[Output Directory])
        
		//Check input and general (don't vary by stage)
        //Note that path processing is coded using *input*, and only applied for typ="Input"
        CheckList = {"Input", "General"}
        for typ in CheckList do
            for _id = 1 to DefArgs.(typ).Length do
                itempair = DefArgs.(typ)
                id = itempair[_id][1]
                itempair = DefArgs.(typ).(id)
                for _item = 1 to itempair.length do
                    item = itempair[_item][1]  
                    //Process Input Values (files) separately
                    if lower(item) = "value" and lower(typ) = "input" then do
                        if Args.(typ).(id).Value = null or ArrayPosition(SkipItems, {item}, ) > 0 then do //Use default...
                            ModArgs.(typ).(id).Value = Scen.IO.GetFullPath(DefArgs.(typ).(id).(item), Args.Info.[Input Directory])
                        end
                        else do //... or scenario specific value
                            ModArgs.(typ).(id).Value = Scen.IO.GetFullPath(Args.(typ).(id).(item), Args.Info.[Input Directory])
                        end
                    end //filenames
                    else do //Remaining (non-filename) items
                        //Default value...
                        if Args.(typ).(id).Value = null or Args.(typ).(id).(item) = null or ArrayPosition(SkipItems, {item}, ) > 0 then do
                            ModArgs.(typ).(id).(item) = DefArgs.(typ).(id).(item)
                        end
                        else do //... or use scenario specific
                            ModArgs.(typ).(id).(item) = Args.(typ).(id).(item)
                        end
                    end //not filenames
                end //for _item
            end //for _id
        end //typ
        
		//Check remaining (vary by stage)
        //Note that path processing is coded using *output*, and only applied for typ="Output"
        CheckList = {"Output", "Param", "Table", "dbTable"}
        for typ in CheckList do
            for _stage = 1 to DefArgs.(typ).Length do
                itempair = DefArgs.(typ)
                stage = itempair[_stage][1]
                for _id = 1 to DefArgs.(typ).(stage).length do
                    itempair = DefArgs.(typ).(stage)
                    id = itempair[_id][1]
                    
                    itempair = DefArgs.(typ).(stage).(id)
                    for _item = 1 to itempair.length do
                        item = itempair[_item][1]
                        //Process Output Values (files) separately
                        if lower(item) = "value" and lower(typ) = "output" then do
                            if Args.(typ).(stage).(id).Value = null or ArrayPosition(SkipItems, {item}, ) > 0 then do
                                ModArgs.(typ).(stage).(id).Value = Scen.IO.GetFullPath(DefArgs.(typ).(stage).(id).Value, Args.Info.[Output Directory])
                            end
                            else do
                                ModArgs.(typ).(stage).(id).Value = Scen.IO.GetFullPath(Args.(typ).(stage).(id).Value, Args.Info.[Output Directory])
                            end
                        end
                        else do  //Remaining (non-value) items
                            //Default value...
                            if Args.(typ).(stage).(id).Value = null or Args.(typ).(stage).(id).(item) = null or ArrayPosition(SkipItems, {item}, ) > 0 then do
                                ModArgs.(typ).(stage).(id).(item) = DefArgs.(typ).(stage).(id).(item)
                            end
                            else do  //... or use scenario specific
                                ModArgs.(typ).(stage).(id).(item) = Args.(typ).(stage).(id).(item)
                            end
                        end //non-value
                    end //_item
                end // _id
            end //_stage
        end //_typ
		
		ModArgs = CopyArray(ModArgs)  //Prevent accidental pointers to table arrays
		Return(ModArgs)
	
	enditem
	//EndMethod
	
	Macro "GetFiles" (SubArgs, Type, ModeSetting) do
    //GetFiles:
    // Checks file status for the input subarray and returns an array formatted for the scenario manager grid
    //  - SubArgs: An argument sub-array containing input or output keys and values
    //             (e.g., SubArgs.Network.Value = XXX, etc.)
    //  - Type: Must be "Input" or "Output" - Defaults to "Output" if no value or an invalid value is passed
		if Type = "Input" then TrimSize = 70
		else do
			Type = "Output"
			TrimSize = 55
		end
		numfiles = SubArgs.length
		if numfiles > 0 then do
			dim FileArr[numfiles]
			dim FileArrTrim[numfiles]
			dim FileStat[numfiles]
			dim FileStatColor[numfiles]
			dim ScrollForm[numfiles]
			dim GridList[numfiles]
			//Make arrays with just filenames, status
			//And then combine into format arrays for the list
			
			//Define colors for grid cells
			ExistColorOpt   = {{"Background Color", ColorRGB(49407,56575,49407)}}    //Green
			
			//Define colors and texts based on status
			StatOpt.Input.Missing.Required.Text    = "<Missing - Required>"
			StatOpt.Input.Missing.Optional.Text    = "<Missing - Optional>"
			StatOpt.Input.Missing.[Not Used].Text  = "<Missing - Not Used>"
			StatOpt.Input.Missing.Required.Color   = {{"Background Color", ColorRGB(64000,40960,40960)}}    //Red
			StatOpt.Input.Missing.Optional.Color   = {{"Background Color", ColorRGB(65535,57855,30975)}}    //Yellow
			StatOpt.Input.Missing.[Not Used].Color = {{"Background Color", ColorRGB(54528,52736,59136)}}    //Gray  
			
			StatOpt.Input.Exists.Required.Text    = "<Exists - Required>"
			StatOpt.Input.Exists.Optional.Text    = "<Exists - Optional>"
			StatOpt.Input.Exists.[Not Used].Text  = "<Exists - Not Used>"
			StatOpt.Input.Exists.Required.Color   = {{"Background Color", ColorRGB(49407,56575,49407)}}    //Green
			StatOpt.Input.Exists.Optional.Color   = {{"Background Color", ColorRGB(49407,56575,49407)}}    //Green
			StatOpt.Input.Exists.[Not Used].Color = {{"Background Color", ColorRGB(54528,52736,59136)}}    //Gray 
			
			StatOpt.Output.Missing.Required.Text    = "<Missing>"
			StatOpt.Output.Missing.Optional.Text    = "<Optional>"
			StatOpt.Output.Missing.[Not Used].Text  = "<Not Used>"
			StatOpt.Output.Missing.Required.Color   = {{"Background Color", ColorRGB(64000,40960,40960)}}    //Red
			StatOpt.Output.Missing.Optional.Color   = {{"Background Color", ColorRGB(65535,57855,30975)}}    //Yellow
			StatOpt.Output.Missing.[Not Used].Color = {{"Background Color", ColorRGB(54528,52736,59136)}}    //Gray 
			
			StatOpt.Output.Exists.Required.Text    = "<Exists>"
			StatOpt.Output.Exists.Optional.Text    = "<Exists>"
			StatOpt.Output.Exists.[Not Used].Text  = "<Exists>"
			StatOpt.Output.Exists.Required.Color   = {{"Background Color", ColorRGB(49407,56575,49407)}}    //Green
			StatOpt.Output.Exists.Optional.Color   = {{"Background Color", ColorRGB(49407,56575,49407)}}    //Green
			StatOpt.Output.Exists.[Not Used].Color = {{"Background Color", ColorRGB(54528,52736,59136)}}    //Gray 
			
			for _file = 1 to numfiles do
			
				_key = SubArgs[_file][1]
				KeyData = SubArgs.(_key)
				req = KeyData.(ModeSetting)
				if req = null then req = "Required" //Default to required if not present
                if Upper(req) = "PARTIAL" then do
                    PartialOK = True
                    req = "Required"
                end else do
                    PartialOK = False
                end

				FileArr[_file] = KeyData.Value
				FileArrTrim[_file] = RunMacro("TCU trim filename", KeyData.Value, TrimSize)

				//Status for files
                if self.CheckFile(FileArr[_file], PartialOK) then stat = "Exists"
                else stat = "Missing"
					
				FileStat[_file] = StatOpt.(Type).(stat).(req).Text
				FileStatColor[_file] = StatOpt.(Type).(stat).(req).Color
				
				if FileStat[_file] = null then FileStat[q] = "<???>"
				
				//Create formatting array - for grid format, input files
				GridList[_file] = {{_key, FileStatColor[_file]}, {FileArrTrim[_file], FileStatColor[_file]},  {FileStat[_file], FileStatColor[_file]}}
			end //end loop over files
		end
		else do  //If no files are available in this step
			//DisableItem("FileList")
			FileArr = {"<No Files>"}
			GridList = null
		end
		
		Return({FileArr, GridList})
	EndItem
	//EndMethod
	
	Macro "GetAdv" (SubArgs, Type, ModeSetting) do
    
    //GetAdv:
    // Reads tables, parameters, and Access tables and returns an array formatted for the scenario manager grid
    //  - SubArgs: An argument sub-array containing param, table, or dbTable keys and values
    //             (e.g., SubArgs.INI.NetYear.Value = XXX, etc.)
    //  - Type: Must be "Param" or "Table" or "dbTable" - Defaults to "Param" if no value or an invalid value is passed
    //  - Added "General" as a fourth option for DRCOG model (Dec 2015)

	
		//Access the IO object, which is part of the main Scen object.
		shared Scen
		
        AllowedKeys = {"Param", "Table", "DbTable", "General"}
        if ArrayPosition(AllowedKeys, {Type}, ) = 0 then Type = "Param"
        
        //if Type = "General" then SubArgs = {{"ALL", SubArgs}}
        
		TrimSize = 70

		numlines = SubArgs.length
		if numlines > 0 then do
			dim LineArr[numlines]
			dim GridList[numlines]
			
			//Make arrays with just parameter keys and values
			//And then combine into format arrays for the list
			
			for _line = 1 to numlines do
			
				_key = SubArgs[_line][1]
				KeyData = SubArgs.(_key)
				req = KeyData.(ModeSetting)
				ValOpt = null
				ValOpt.[Read Only] = False
				if req = null then req = "Required" //Default to required if not present

                //Deal with arrays
				ValOpt = null
				if TypeOf(KeyData.Value) = "array" then do
                   	// Switched to full array in list (smc- 08-26-2013_
                    //LineArr[_line] = Scen.IO.ArrayStringSub(KeyData.Value)
                    LineArr[_line] = Scen.IO.ArrayStringFull(KeyData.Value)
					ValOpt.[List] = {"Edit...", "Type Value...", "Set to null"}
				end
				else if TypeOf(KeyData.Value) = "string" then do
                    LineArr[_line] = KeyData.Value
                    if KeyData.Value = "True" or KeyData.Value = "False" then do
                        ValOpt.[List] = {"True", "False"}
                    end
				end
				else if TypeOf(KeyData.Value) = "int" then do
					 LineArr[_line] = format(KeyData.Value, "*.")
					end
				else do
					 LineArr[_line] = format(KeyData.Value, "*.0*")
				end

				//Create formatting array - for grid format, input files
				GridList[_line] = {{_key, }, {LineArr[_line], CopyArray(ValOpt)}}
			end //end loop over files
		end
		else do  //If no files are available in this step
			//DisableItem("FileList")
			LineArr = {"<No Files>"}
			GridList = null
		end
		
		Return({LineArr, GridList})
	enditem
	//EndMethod

    Macro "Simplified" (Args) do
    
        //Return a simplified Args array that references all files, params, and
        //  tables simply by Args.[Key Name].  Throws an error if there are
        //  any duplicate keys.  This is useful for bringing this scenario 
        //  manager directly to models that use Caliper's scenario manager.
        
        //The Info variable from the scenario manger is added to the .Info key, 
        // including [Scenario Name], [Input Directory], [Output Directory], etc.
        
        shared Scen
        
        keys = {"Input", "Output", "Param", "Table"}
        stages = Scen.StageIndex
        
        Simp = null
        for key in keys do
        
            if key = "Input" then do
                for ii = 1 to Args.Input.length do
                    name = Args.Input[ii][1]
                    Simp.(name) = Args.Input.(name).Value
                end
            end else do
                for stage in stages do
                
                    if Args.(key).(stage) != null then do
                    
                        for ii = 1 to Args.(key).(stage).length do
                            name = Args.(key).(stage)
                            name = name[ii][1]
                            Simp.(name) = Args.(key).(stage).(name).Value
                        end
                    end
                
                end //for stage
            
            end //else (not input)
        
        end //for key in keys
        
        if Simp.Info != null then do
            Throw('Error: Scenario parameter cannot be named "Info"')
        end else do
            Simp.Info = Args.Info
        end
        
        Return(Simp)
    
    
    enditem //EndMethod
    
    Macro "SubSteps" (idx) do
    
        shared Scen
        stage_name = Scen.StageNames[idx]
        step_names = Scen.StepMacro[idx]
        in_flag = Scen.StepSwitch[idx]
        disable = Scen.StepDisable[idx]
        
        //switch = RunDbox("SubSteps", title, step_names, in_flag, disable)
        switch = RunDbox("SubSteps", stage_name, step_names, in_flag, disable)
        if switch != null then Scen.StepSwitch[idx] = CopyArray(switch)
	enditem //EndMethod
    
    Macro "AllSteps" do
    
        shared Scen
        stage_names = Scen.StageNames
        step_names = Scen.StepMacro
        in_flag = Scen.StepSwitch
        disable = Scen.StepDisable
        
        //switch = RunDbox("SubSteps", title, step_names, in_flag, disable)
        switch = RunDbox("AllSteps", stage_names, step_names, in_flag, disable)
        if switch != null then Scen.StepSwitch = CopyArray(switch)
	enditem //EndMethod
    
    
    //Check the SEMCOG SED Switch, set requirements for disaggregate and aggregate SED
    Macro "SEMCOG_SEDSwitch" (Args) do

		if Args.Param.CVM.UseStaticCVMTrips.Value then do
			Args.Input.[CVM Static Trip Table].Choice = "Required"
			Args.Input.[Facilities Data].Choice = "Not Used"
			Args.Input.[CVM IEEI Trucks].Choice = "Not Used"
			Args.Input.[CVM EE Trucks].Choice = "Not Used"
			Args.Input.[CVM Externals].Choice = "Not Used"
			Args.Input.[CVM Batch File].Choice = "Not Used"
			Args.Input.[Buffer TAZ Data].Choice = "Not Used"
			Args.Input.[Base Year Firms].Choice = "Not Used"
			Args.Output.CVM.[Firm Synthesis Database].Choice = "Not Used"
			Args.Output.CVM.[Long Distance Database].Choice = "Not Used"
			Args.Output.CVM.[Commercial Vehicle Tours].Choice = "Not Used"
			Args.Output.CVM.[CVM Trip Database].Choice = "Not Used"
			Args.Output.CVM.[CVM Trip Generation].Choice = "Not Used"
			Args.Output.CVM.[CVM Dashboard].Choice = "Not Used"
		end else do
			Args.Input.[CVM Static Trip Table].Choice = "Not Used"
			Args.Input.[Facilities Data].Choice = "Required"
			Args.Input.[CVM IEEI Trucks].Choice = "Required"
			Args.Input.[CVM EE Trucks].Choice = "Required"
			Args.Input.[CVM Externals].Choice = "Required"
			Args.Input.[CVM Batch File].Choice = "Required"
			Args.Input.[Buffer TAZ Data].Choice = "Required"
			Args.Input.[Base Year Firms].Choice = "Optional"

			if Args.Param.CVM.BaseScenario.Value then do
				Args.Input.[Base Year Firms].Choice = "Optional"
			end else do	
				Args.Input.[Base Year Firms].Choice = "Required"
			end
		end


    
    enditem //EndMethod
    
EndClass


//Sub Steps macro:
// this dbox allows sub-steps to be turned on or off.

Dbox "SubSteps" (stage_name, step_names, in_flag, disabled) resize title: "Select Steps" 
    Location: SUBSTEP_x, SUBSTEP_y 

	init do
        shared ui_dir
        clr = RunMacro("G30 setup colors")
		buffer = CopyArray(in_flag)
        
        //Define location and selected scenario
        //Dialog box will be right-center, but will remember its location
        static SUBSTEP_x, SUBSTEP_y
        if SUBSTEP_x = null then SUBSTEP_x = -3
        
        //Create grid view
        dim grid_cols[2]
        
        grid_cols[1].Name = ""
        grid_cols[1].Images = {"bmp\\Check0.bmp", "bmp\\Check1.bmp", ui_dir+"bmp\\Check2.bmp", "bmp\\no.bmp"}
        grid_cols[1].Width = 6
        grid_cols[1].Alignment = "Right"
        
        grid_cols[2].Name = ""
        grid_cols[2].Width = null
        
        dim grid_info[step_names.length + 1]
        OP = null
        OP.Image = 1
        OP.[Background Color] = clr[54]
        OP.Alignment = "Left"
        grid_info[1] = {{null, CopyArray(OP)}, 
                        {stage_name, {{"Background Color", clr[54]}}}}
                        
        for ii = 1 to step_names.length do
            
            OP = null
            OP.Image = if buffer[ii] = 1 then 2 else 1
            OP.Alignment = "Right"
            if disabled[ii] then 
                OP.Image = 4
            grid_info[ii+1] = {{null ,CopyArray(OP)}, 
                             {step_names[ii], null}}
        end
        
        RunMacro("UpdateGrid")

	enditem
    
    macro "UpdateGrid" do
    
        AllChecked = True
        NoneChecked = True
        for ii = 1 to step_names.length do
            if !disabled[ii] then do
                if !buffer[ii] then AllChecked = False
                else NoneChecked = False
            end
        end
        
        if AllChecked then 
            img = 2
        else if NoneChecked then
            img = 1
        else 
            img = 3
            
        grid_info[1][1][2].Image = img
        
    enditem
	
	grid view 1, 1, 60, 17 Columns: grid_cols List: grid_info variable: click_idx 
        resize: width, height do
    
        if click_idx[2] = 1 then do
        
            if click_idx[1] = 1 then do
                status = grid_info[1][1][2].Image
                if status = 2 then //if checked
                    newStat = 1 //then un-checked
                else
                    newStat = 2 //checked
                    
                for ii = 1 to buffer.length do
                    if !disabled[ii] then do
                        grid_info[ii+1][1][2].Image = newStat
                        buffer[ii] = if newStat=2 then 1 else 0
                    end
                end
       
            end else if !disabled[click_idx[1] - 1] then do
                r = click_idx[1] - 1
                if buffer[r] = 1 then
                    buffer[r] = 0
                else 
                    buffer[r] = 1
                    
                grid_info[r+1][1][2].Image = if buffer[r] = 1 then 2 else 1
            end
        
        end
        
        RunMacro("UpdateGrid")
        
    enditem
	

	
	button "OK" 40, 19, 10, 1.5 resize: top, left default do
		Return(buffer)
	enditem
	
	button "Cancel" after, same, 10, 1.5 resize: top, left cancel do
		Return()
	enditem
	
EndDbox

//All Steps macro:
// this dbox allows sub-steps from all stages to be turned on or off.

Dbox "AllSteps" (stage_names, step_names, in_flag, disabled) resize title: "Select Steps" 
    Location: SUBSTEP_x, SUBSTEP_y 

	init do
        shared ui_dir
        clr = RunMacro("G30 setup colors")
		buffer = CopyArray(in_flag)
        
        //Define location and selected scenario
        //Dialog box will be right-center, but will remember its location
        static ALLSTEP_x, ALLSTEP_y
        if ALLSTEP_x = null then ALLSTEP_x = -3
        
        //Create grid view
        dim grid_cols[2]
        
        grid_cols[1].Name = ""
        grid_cols[1].Images = {"bmp\\Check0.bmp", "bmp\\Check1.bmp", ui_dir+"bmp\\Check2.bmp", "bmp\\no.bmp"}
        grid_cols[1].Width = 6
        grid_cols[1].Alignment = "Right"
        
        grid_cols[2].Name = ""
        grid_cols[2].Width = null
        
        grid_info = null
        dim stage_idx[stage_names.length+1]
        for ii = 1 to stage_names.length do
        
            OP = null
            OP.Image = 1
            OP.[Background Color] = clr[54]
            OP.Alignment = "Left"
            grid_info = grid_info + {  {{null, CopyArray(OP)}, 
                                       {stage_names[ii], {{"Background Color", clr[54]}}}}  }

            stage_idx[ii] = grid_info.length  //Track grid headers
                
            for jj = 1 to step_names[ii].length do
                
                OP = null
                OP.Image = if buffer[ii][jj] = 1 then 2 else 1
                OP.Alignment = "Right"
                if disabled[ii][jj] then 
                    OP.Image = 4
                grid_info = grid_info + {  {{null ,CopyArray(OP)}, 
                                           {step_names[ii][jj], null}}   }
                                           
            end
        end //ii
        
        stage_idx[stage_idx.length] = grid_info.length
        
        RunMacro("UpdateGrid")

	enditem
    
    macro "UpdateGrid" do
    
        for ii = 1 to stage_names.length do
            AllChecked = True
            NoneChecked = True
        
            for jj = 1 to step_names[ii].length do
                if !disabled[ii][jj] then do
                    if !buffer[ii][jj] then AllChecked = False
                    else NoneChecked = False
                end
            end //jj
        
        if AllChecked then 
            img = 2
        else if NoneChecked then
            img = 1
        else 
            img = 3
            
        grid_info[stage_idx[ii]][1][2].Image = img
    end //ii
        
    enditem
    
    button "All On" 1, 0.5, 10, 1 do
        all_status = 1
        RunMacro("SetAll")
    enditem
    
    button "All Off" after, 0.5, 10, 1 do
        all_status = 0
        RunMacro("SetAll")
    enditem
    
    macro "SetAll" do
        for ii = 1 to buffer.length do
            for jj = 1 to buffer[ii].length do
            
            if !disabled[ii][jj] then do
                    //Set buffer
                    buffer[ii][jj] = all_status
                    
                    //Update the grid
                    grid_info[stage_idx[ii]+jj][1][2].Image = if all_status=1 then 2 else 1
                end
            end
        end
        RunMacro("UpdateGrid")
    enditem
	
	grid view 1, 2, 60, 30 Columns: grid_cols List: grid_info variable: click_idx 
        resize: width, height do
    
        if click_idx[2] = 1 then do  //clicked in first column
        
            //Detect section clicked in
            row_idx = click_idx[1]
            ii = ArrayPosition(stage_idx, {row_idx}, )
            header = if ii > 0 then True else False
            
            //Section clicked if not on a header
            if !header then do
                for ii = 1 to stage_idx.length do
                    if row_idx < stage_idx[ii+1] then break
                end
                
                jj = row_idx - stage_idx[ii]
            end
            
            if header then do //Clicked header row
            
                status = grid_info[click_idx[1]][1][2].Image
                if status = 2 then //if checked
                    newStat = 1 //then un-checked
                else
                    newStat = 2 //checked
                    
                for jj = 1 to buffer[ii].length do
                    if !disabled[ii][jj] then do
                        grid_info[click_idx[1]+jj][1][2].Image = newStat
                        buffer[ii][jj] = if newStat=2 then 1 else 0
                    end
                end
       
            //Clicked an individual step
            end else if !disabled[ii][jj] then do
                if buffer[ii][jj] = 1 then
                    buffer[ii][jj] = 0
                else 
                    buffer[ii][jj] = 1
                    
                grid_info[row_idx][1][2].Image = if buffer[ii][jj] = 1 then 2 else 1
            end
        
        end
        
        RunMacro("UpdateGrid")
        
    enditem
	
	button "OK" 40, 34, 10, 1.5 resize: top, left default do
		Return(buffer)
	enditem
	
	button "Cancel" after, same, 10, 1.5 resize: top, left cancel do
		Return()
	enditem
	
EndDbox


//Class for Scenario IO
// ReadINI: Read an INI file into a default scenario array (i.e., an array witout specified paths)
// --> ReadParams: Read an array of parameter strings
// WriteINI: Write a scenario to an INI file
// --> WriteParams: Write an array of parameter strings
// StrConv: Read a string and convert to real/integer/array/string based on contents
// ArrayStringSub: Convert an array to a formatted string
// DirFormat: Checks for a trailing backslash and adds if needed
// GetFullPath: Checks to see if a filename includes a path, if not - adds a relative path to get a complete path
// EditNetYears: Open the edit network years dialog box

Class "Scen.IO"
//StartClass
	//Read an INI file into a scenario array
	//if Sort is True, then the data will be sorted by adding a Sort option to each read array
	//Currently no options
	//Returns the scenario Args array
	
	Macro "ReadINI" (Filename, Sort, Opts) do

		//Read the file into an array, then close the INI file
		fp = OpenFile(Filename, "r")
		arr = ReadArray(fp)
		i = 1		
		CloseFile(fp)
		
		//Clear the Args array that will be filled with the information in the INI file
		Args = null
		
		//Process each line
		While i <= arr.Length do
			
		    st = Trim(arr[i])  //st = a trimmed (no leading/trailing spaces) line from the file
			if left(st, 1) = ";" or st = null then do //Skip comment and blank lines
				i = i + 1
			end 
			else do
				//allow end of line comments
				st = ParseString(st, ";", )
				st = Trim(st[1])
				
				//Get section (if the first line is not a section name, an error will be raised)
				if left(st, 1) <> "[" or right(st, 1) <> "]" then do
					ShowMessage("Error in Scenario File " + Filename + " on line " + string(i) + ".\n * ReadINI - Expected section name *")
					Return()
				end
						
				st = Substring(st, 2, len(st) - 2)  //Remove [ and ]
				Sec = ParseString(st, ".", )       //Separate by . to allow for multiple element section names (up to 3 only)
				
				// ------------------- Process 1-element section names ---------------------
				// (no sorting)
				if Sec.Length = 1 then do
					Sec = Sec[1]
					Args.(Sec) = self.ReadParams(arr, &i)  //allow i to be changed by the macro
				end //end one-element read
				
				// ------------------- Process 2-element section names ---------------------
				else if Sec.Length = 2 then do
					//Special treatment for shorthand
					if Sec[1] = "Param" or Sec[1] = "Table" or Sec[1] = "DbTable" or Sec[1] = "Output" then do
						//Read the values
						StartLine = i
						tmpOpts = self.ReadParams(arr, &i)  //allow i to be changed by the macro
						
						for j = 1 to tmpOpts.length do
							vals = ParseString(tmpOpts[j][2], "|", {{"Include Empty", "True"}})
							if vals.length < 2 then do
								//ShowMessage("Error in Scenario File " + Filename + " on line " + string(i+j) + ". \n * Incorrect shorthand format *")
								Throw("Error in Scenario File " + Filename + " on line " + string(StartLine+j) + ". \n * Incorrect shorthand format *")
								Return()
							end
							
							//Get sort value
							SortOpts.(Sec[1]).(Sec[2]) = nz(SortOpts.(Sec[1]).(Sec[2])) + 1
							
							Args.(Sec[1]).(Sec[2]).(tmpOpts[j][1]).Value = self.StrConv(Trim(vals[1]))
							Args.(Sec[1]).(Sec[2]).(tmpOpts[j][1]).Desc = Trim(vals[2])
							if vals.length >= 3 then Args.(Sec[1]).(Sec[2]).(tmpOpts[j][1]).Choice = Trim(vals[3])
							if vals.length >= 4 then Args.(Sec[1]).(Sec[2]).(tmpOpts[j][1]).Split = Trim(vals[4])
							Args.(Sec[1]).(Sec[2]).(tmpOpts[j][1]).Sort = SortOpts.(Sec[1]).(Sec[2])
						end //end reading shorthand 
						
					end //end if shorthand Param format
					
					//Standard 2-element
					else do
						//Get proper sort value
						AddOpts = null
						if Sort then do
							SortOpts.(Sec[1]) = nz(SortOpts.(Sec[1])) + 1
							AddOpts = {{"Sort", SortOpts.(Sec[1])}}
						end
					
						//Read values
						Args.(Sec[1]).(Sec[2]) = self.ReadParams(arr, &i, AddOpts)  //allow i to be changed by the macro
					end
				end //end two-element read
				// ------------------- Process 3-element section names ---------------------
				else do
					//Get proper sort value
					AddOpts = null
					if Sort then do
						SortOpts.(Sec[1]).(Sec[2]) = nz(SortOpts.(Sec[1]).(Sec[2])) + 1
						AddOpts = {{"Sort", SortOpts.(Sec[1]).(Sec[2])}}
					end

					//Read values
					Args.(Sec[1]).(Sec[2]).(Sec[3]) = self.ReadParams(arr, &i, AddOpts)  //allow i to be changed by the macro
				end
			end //End not a comment or blank
		end //end while not EOF
		
		Return(Args)
		
	enditem //End Read INI macro
	//EndMethod
	
	Macro "ReadParams" (arr, i, AddOpts) do //Read parameters - 
	//arr = array of read file lines
	//i = line to read
	//AddOpts = Additional options to add to the Options array (e.g., a sort option based on read order)
	
		Params = null
		i = i + 1
		while (i <= arr.length) and (left(Trim(arr[i]), 1) <> "[") do
			st = Trim(arr[i])
			if left(st, 1) <> ";" and st <> null and Trim(st) <> "" then do //Skip comment and blank lines
				//allow end of line comments
				st = ParseString(st, ";", )
				st = Trim(st[1])
				
				//Allow line continuation
				while Position(",+-*/", right(st, 1)) > 0 do
					if left(st, 1) = ";" or st = null then do //Skip comment and blank lines
						i = i + 1
					end 
					else do
						i = i + 1
						cont = Trim(arr[i])
						//allow end of line comments
						cont = ParseString(cont, ";", )
						cont = Trim(cont[1])
						st = st + cont
					end
				end
				
				//Remove potential tabs
				st = Substitute(st, "	", " ", )
				
				//Read the name=value pair
				st = ParseString(st, "=", {{"Include Empty", "True"}})
				if st.Length >= 2 then do  //Silently ignore invalid lines
					//Trim spaces from the name
					nam = Trim(st[1])
					
					//Allow equal signs in the value
					val = st[2]
					for j = 3 to st.length do
						val = val+"="+st[j]
					end
					
					//Trim spaces from the value
					val = Trim(val)
					
					//convert to numeric if applicable
					val = self.StrConv(val, i-1)
					
					//Append to the array
					//Allow for dot-notation in name to allow up to one sub-array
					nam = ParseString(nam, ".")
					if nam.length = 1 then do
						Params.(nam[1]) = val
					end
					else if nam.length >= 2 then do
						Params.(nam[1]).(nam[2]) = val
					end
					
						
				end //end reading valid parameters=
			end //end skipping comments
			i = i + 1
		end// while not at the next section or EOF
		
		//Add additional Opts
		if AddOpts <> null then do
			Params = Params + AddOpts
		end
		
		Return(Params)
	endItem
	//EndMethod

	//Write an INI file based on a scenario array
	//the format of the INI file will be based on the format of the default INI file
	// out_file = Location to save INI file
	// Args = Args array to format *Note - This array MUST have been checked using CheckScen
	// def_file = Default INI filename
	//Currently no options
	
	Macro "WriteINI" (out_file, Args, def_file, Opts) do

		//Read the default file into an array, then close the INI file
		fp = OpenFile(def_file, "r")
		arr = ReadArray(fp)
		i = 1		
		CloseFile(fp)
		
		//Open the output file - clear if overwriting
		fp = OpenFile(out_file, "w")
		
		//Process each line
		While i <= arr.Length do
			
			st_orig = arr[i]
			
			if left(st_orig, 1) = ";" or st_orig = null then do //No change to comment or blank lines
				WriteLine(fp, st_orig)
				i = i + 1
			end
			else do
				//allow end of line comments
				st_parts = ParseString(st_orig, ";", )
				st = Trim(st_parts[1])
				
				//Get section (if the first line is not a section name, an error will be raised)
				if left(st, 1) <> "[" or right(st, 1) <> "]" then do
					ShowMessage("Error in Scenario File " + def_file + " on line " + string(i) + ".\n * WriteINI - Expected section name *")
					Return()
				end
						
				st = Substring(st, 2, len(st) - 2)  //Remove [ and ]
				Sec = ParseString(st, ".", )       //Separate by . to allow for multiple element section names (up to 3 only)
				
				//Write the section header (no changes to string)
				WriteLine(fp, st_orig)
				
				// ------------------- Process 1-element section names ---------------------
				if Sec.Length = 1 then do
					self.WriteParams(fp, Args, Sec, arr, &i)  //allow i to be changed by the macro
				end //end one-element read
				
				// ------------------- Process 2-element section names ---------------------
				else if Sec.Length = 2 then do
					//Special treatment for shorthand
					if Sec[1] = "Param" or Sec[1] = "Table" or Sec[1] = "DbTable" or Sec[1] = "Output" then do
						self.WriteParams(fp, Args, Sec, arr, &i, {{"Shorthand", True}})  //allow i to be changed by the macro
						//self.WriteParamsSH(fp, Args, Sec, arr, &i )  //allow i to be changed by the macro
					end
					
					//Standard 2-element
					else do
						self.WriteParams(fp, Args, Sec, arr, &i)  //allow i to be changed by the macro
					end
				end //end two-element read
				// ------------------- Process 3-element section names ---------------------
				else do
					self.WriteParams(fp, Args, Sec, arr, &i)  //allow i to be changed by the macro
				end
			end //End not a comment or blank
		end //end while not EOF
		
		Return(Args)
		
	enditem //End Read INI macro
	//EndMethod
	
	//Write parameters to an INI file (to be called from WriteINI)
	// fp = file handle of output file
	// Args = Args array of scenario being written
	// Sec = array of section components
	// arr = array of lines read from default INI file
	// i = template file line with section header (must be passed as &i)
	//     --> Reading/writing will continue until the section ends
	//
	// Options:
	// Opts.Shorthand = True/False = If True, input is assumed to be in shorthand format
	
	Macro "WriteParams" (fp, Args, Sec, arr, i, Opts) do //Write parameters - 

	
		//Check for option to write in shorthand format
		if Opts.Shorthand = True then SH = True
		
		i = i + 1
		while (i <= arr.length) and (left(Trim(arr[i]), 1) <> "[") do
			st_orig = arr[i]
			st_trim = Trim(st_orig)
			if left(st_trim, 1) = ";" or st_trim = null or st_trim = "" then do //Write comment and blank lines as is
				WriteLine(fp, st_orig)
			end
			else do
				//allow end of line comments
				st_parts = ParseString(st_orig, ";", )
				
				//Allow line continuation
				// * NOTE: Continued lines will be exported as a single line! *					
				// * NOTE: All end of line comments will be removed (except for first continued line) * 
				continue = False
				if Position(",+-*/", right(st_trim, 1)) > 0 then do
					continue = True
					st_mod = st_orig
					i_start = i
					while Position(",+-*/", right(st_mod, 1)) > 0 do
						i = i + 1
						cont = Trim(arr[i]) //trim subsequent lines
						//remove all end of line comments
						cont = ParseString(cont, ";", )
						cont = Trim(cont[1])
						st_mod = st_mod + cont
					end
					st_parts[1] = st_mod
				end
				i_end = i
				
				//Trim and remove potential tabs for reading
				st = Trim(st_parts[1])
				st = Substitute(st, "	", " ", )
				
				//Read the name=value pair and adjust in the output file
				st = ParseString(st, "=", {{"Include Empty", "True"}})
				if st.Length >= 2 then do  //Silently ignore (and do not write) invalid lines 
				
					//Trim spaces from the name
					nam = Trim(st[1])
					
					//Allow equal signs in the value
					val = st[2]
					for j = 3 to st.length do
						val = val+"="+st[j]
					end
					
					//Trim spaces from the value
					val = Trim(val)
					
					if SH then do  //Adjust for shorthand entry
						st_sh = ParseString(val, "|", {{"Include Empty", "True"}})
						val = Trim(st_sh[1])
						val = self.StrConv(val, i-1)
						
						//1 = Value
						//2 = Description - NOT CHECKED - Default is written
						//3 = Choice (optional) - NOT CHECKED - Default is written
						
						//1: Value
						new_val = null
						if Sec.Length = 1 then new_val = Args.(Sec[1]).(nam).Value
						else if Sec.Length = 2 then new_val = Args.(Sec[1]).(Sec[2]).(nam).Value
						else if Sec.Length = 3 then new_val = Args.(Sec[1]).(Sec[2]).(Sec[3]).(nam).Value
						
					end //shorthand adjustment					
					else do //Non-shorthand
					
						st_sh = null //No shorthand string (for desc and options)
						
						//convert to numeric if applicable
						val = self.StrConv(val, i-1)
					
						//Compare read value to current scenario value
						new_val = null
						nam_parts = ParseString(nam, ".")
						if nam_parts.length = 1 then do  //Single part name (e.g.  .Value)
							if Sec.Length = 1 then new_val = Args.(Sec[1]).(nam)
							else if Sec.Length = 2 then new_val = Args.(Sec[1]).(Sec[2]).(nam)
							else if Sec.Length = 3 then new_val = Args.(Sec[1]).(Sec[2]).(Sec[3]).(nam)
						end
						else if nam_parts.length = 2 then do  //Two part name (e.g.,   .Value.FT)
							if Sec.Length = 1 then new_val = Args.(Sec[1]).(nam_parts[1]).(nam_parts[2])
							else if Sec.Length = 2 then new_val = Args.(Sec[1]).(Sec[2]).(nam_parts[1]).(nam_parts[2])
							else if Sec.Length = 3 then new_val = Args.(Sec[1]).(Sec[2]).(Sec[3]).(nam_parts[1]).(nam_parts[2])
						end
						else do  //More than 2 parts / other problem (e.g.,   .Value.FT)
							Throw("Error on line " + string(line) + " of default ini file. \n * Subarray with more than two parts *")
						end
							
					end
					
					if self.ArrayCompare(new_val, val) then do  //No change if values match
						if continue then do  //Write continued lines as is if values match
							for i_continue = i_start to i_end do
								WriteLine(fp, arr[i_continue])
							end
						end
						else do
							WriteLine(fp, st_orig) //Or non-continued
						end
					end
					else do
						if TypeOf(new_val) = "array" then str_val = self.ArrayStringSub(new_val)
						
						//Extract relative filenames from file strings
						else if TypeOf(new_val) = "string" then do
							if Sec[1] = "Input" then do
								str_val = self.GetRelPath(new_val, Args.Info.[Input Directory])
							end
							else if Sec[1] = "Output" then do
								str_val = self.GetRelPath(new_val, Args.Info.[Output Directory])
							end
							else do
								str_val = new_val
							end
						end
							
						else if TypeOf(new_val) = "null" then str_val = "null"
						else if TypeOf(new_val) = "int" then str_val = Format(new_val, "*.")
						else str_val = Format(new_val, "*.0*")
						
						//Write the data to file - adding appropriate shorthand information and end of line comments
						write_string = nam + " = " + str_val 
						if st_sh <> null and st_sh.length >= 2 then do
							write_string = write_string + " |" + JoinStrings(SubArray(st_sh, 2, ), "|") 
						end
						if st_parts <> null and st_parts.length >= 2 then do
							write_string = write_string + " ;" + JoinStrings(SubArray(st_parts, 2, ), ";")
						end
						WriteLine(fp, write_string)
					end
					
				end //end reading valid parameters
			end //end duplicating comments/blanks
			i = i + 1
		end // while not at the next section or EOF
		
	enditem
	//EndMethod
	
	Macro "WriteParamsSH" (fp, Args, Sec, arr, i) do
	
		WriteLine(fp,"; --Shorthand not implemented--")
		i = i + 1
		while (i <= arr.length) and (left(Trim(arr[i]), 1) <> "[") do
			i = i + 1
		end
		
	
	enditem
	//EndMethod
	
	//Convert a string to a real value, but only
	//if the string is exclusively numeric.
	//Values are converted to integers if no
	//decimals are present (1.0 is a real, 1 is an int)
	//line = inf file line number, or null for interactive use
	
	Macro "StrConv" (st, line) do
	
		//Check for quotes (either "" or'')
		Str = False
		if (left(st,1) = "'" and right(st,1) = "'") or (left(st,1) = '"' and right(st,1) = '"') then do
			Str = True
			st = substring(st, 2, len(st)-2)  //Eliminate quotes
		end
		//check for an array ( {})
		if (left(st,1) = "{" and right(st,1) = "}") then do
			arr = null
			
			//Process arrays here
			st = substring(st, 2, len(st)-2)  //Eliminate brackets
			el = ParseString(st, ",", {{"Include Empty", "True"}})  //Separate elements
			
			//Check for consistent { and }
			tmp1 = ParseString(st, "{", {{"Include Empty", "True"}})
			tmp2 = ParseString(st, "}", {{"Include Empty", "True"}})
			if line <> null then do
				if tmp1.Length <> tmp2.Length then Throw("Error on line " + string(line) + " of default ini file. \n * Inconsistent {} brackets *")
			end
			else do
			if tmp1.Length <> tmp2.Length then do
					ShowMessage("Invalid Entry")
					return()
				end
			end
			
			//Re-assemble sub-arrays
			full_el = CopyArray(el)
			el = null
			i = 1 //el counter (for updated element array)
			for j = 1 to full_el.length do
				if left(trim(full_el[j]), 1) = "{" then do
					tmp = null
					while right(trim(full_el[j]), 1) <> "}" do
						tmp = tmp + full_el[j] + ", "
						j = j + 1
						
						//check for input problems
						if j > full_el.Length then do
						Throw("Error on line " + string(line) + " of ini file. \n * Incorrect array format *")
				end
					end
					tmp = tmp + full_el[j] //one last element - plus last bracket
					el = el + {tmp}
					i = i + 1
					//j is incremented by the loop
				end
				else do
					el = el + {full_el[j]}
					i = i + 1
				end
			end
			
			dim arr[el.length]
			for i = 1 to arr.length do
				arr[i] = self.StrConv(Trim(el[i]), line)
			end
		
		Return(arr)	
		end
			
		
		else do
		
			//Check for null
			if st = "null" or st = null then Return(null)
	
			//Check for non-numeric
			Int = False
			for i = 1 to len(st) do
				if st[i] <> "-" and st[i] <> "." and st[i] <> "0" and s2r(st[i]) = 0 then do
					Str = True
					i = len(st)
				end
			end
			
			//Check decimal count
			tmp = ParseString(st, ".", {{"Include Empty", "True"}})
			if tmp.length > 2 then Str = True
			if tmp.length = 1 then Int = True
		end
		
		if Arr then Return(st)
		if Str then Return(st)
		if Int then Return(s2i(st))
		else Return(s2r(st))
	enditem
	//EndMethod
	
	//Convert an array to a formatted string, using [subarray] where subarrays are present
	Macro "ArrayStringSub" (InArr) do
		Arr = CopyArray(InArr) //Don't risk modifying the input array
		tmp = "{"
		for i = 1 to Arr.length do
			if TypeOf(Arr[i]) = "string" then do
				tmp = tmp + '"'+Arr[i] + '", '
			end
			else if TypeOf(Arr[i]) = "array" then do
				tmp = tmp + "[subarray], "
			end
			else if TypeOf(Arr[i]) = "int" then do
				tmp = tmp + format(Arr[i], "*.*") + ", "
			end
			else do
				tmp = tmp + format(Arr[i], "*.0*") + ", "
			end
		end
		tmp = left(tmp, len(tmp)-2) + "}" //Eliminate trailing comma, add }
		Return(tmp)
	
	enditem
	//EndMethod
    
	//Convert an array to a formatted string, using recursion to get complete array
    //Includes quotes around strings for improved clarity
    //smc: 08-26-2013
	Macro "ArrayStringFull" (InArr) do
		Arr = CopyArray(InArr) //Don't risk modifying the input array
		tmp = "{"
		for i = 1 to Arr.length do
			if TypeOf(Arr[i]) = "string" then do
				tmp = tmp + '"'+Arr[i] + '", '
			end
			else if TypeOf(Arr[i]) = "array" then do
				tmp = tmp + self.ArrayStringFull(Arr[i]) + ", "
			end
			else if TypeOf(Arr[i]) = "int" then do
				tmp = tmp + format(Arr[i], "*.*") + ", "
			end
			else do
				tmp = tmp + format(Arr[i], "*.0*") + ", "
			end
		end
		tmp = left(tmp, len(tmp)-2) + "}" //Eliminate trailing comma, add }
		Return(tmp)
	
	enditem
	//EndMethod
	
//Compares two arrays, returns True if identical, False if not identical
// --> Calls itself recursively to compare nested arrays
// --> Will also work on non-arrays

	Macro "ArrayCompare" (arr1, arr2) do

		//Both not arrays? Do a normal comparison...
		if TypeOf(arr1) <> "array" and TypeOf(arr2) <> "array" then do
			if arr1 = arr2 then Return(True)
			else Return(False)
		end
		
		//One array and one non-array? Return False...
		else if TypeOf(arr1) <> "array" or TypeOf(arr2) <> "array" then do
			Return(False)
		end
		
		//Both arrays? Compare them...
		else do
		
			if arr1.Length <> arr2.Length then Return(False)
			
			//Compare each subarray (using a recursive call)
			for i = 1 to arr1.Length do
				if !self.ArrayCompare(arr1[i], arr2[i]) then Return(False)
			end
			Return(True) //The arrays match if this line has been reached
		end


	enditem
	//EndMethod

	Macro "GetRelPath" (Path, Dir) do
	
		
		//Stop if the string does not look like a path including a file
		if Substring(Path, 2, 2) <> ":\\" or right(Path, 1) = "\\" then Return(Path)
		
		//remove the input path from the string
		Return(  Substitute(Path, Dir, "", 1)  )
	
	enditem
	//EndMethod
	
	Macro "GetFullPath" (Path, Dir) do
		
		//If the sring looks like a real path, return the original string
		if Substring(Path, 2, 2) = ":\\" then Return(Path)
		
		//Otherwise, add the directory
		Return(Dir + Path)
		
	enditem
	//EndMethod
	
	//Macro that checks for a trailing backslash and adds if needed
	Macro "DirFormat" (dir) do
		if Right(dir, 1) = "\\" then ret = dir
		else ret = dir + "\\"
		Return(ret)
	enditem
    //EndMethod
	
	//Macro that calls a dialog box allowing the user to edit the network year
	Macro "EditNetYears" (dbd_file, InOpts) do
		RunDbox("Edit Network Years", dbd_file, InOpts)
	enditem
    //EndMethod
	
EndClass   //End IO Class


//Dialog box to edit an array using a grid.  If subarrays are present, 
//the dialog box can be called recursively.
Dbox "Edit Array" (InArr)

	init do
	
		//Get access to the IO object
		shared Scen
		
		//Make a copy of the input array to edit
		//(TC passes arrays by pointer)
		Arr = CopyArray(InArr)
		
		//Column Settings
		Col1 = null
		Col1.Width = 4
		Col1.Fixed = True
		Col1.[Read Only] = True
		
		Col2 = null
		
		column_info = {Col1, Col2}
		
		//Dimension the grid list and update the grid
		dim grid_list[Arr.length]
		RunMacro("UpdateGrid")
	enditem
	macro "UpdateGrid" do
		for i = 1 to grid_list.length do
			if TypeOf(Arr[i]) = "array" then do
				arr_val = Scen.IO.ArrayStringSub(Arr[i])
				Opts = null
				Opts.List = {"Edit..."}
				grid_list[i] = {{i,}, {arr_val, CopyArray(Opts)}}
			end
			else if TypeOf(Arr[i]) = "string" then do
				 grid_list[i] = {{i, }, {Arr[i], }}
			end
			else if TypeOf(Arr[i]) = "int" then do
				 grid_list[i] = {{i, }, {Format(Arr[i], "*."), }}
			end
			else do
				grid_list[i] = {{i, }, {Format(Arr[i], "*.0*"), }}
			end
		end
	EndItem //UpdateGrid
	
	//The scenario array grid view
	Grid View "ArrayGrid" 1, 1, 40, 20 List: grid_list Columns: column_info Editable Variables: cell, click do
		
		//If the user changes a value (and has not double-clicked in the header column)
		if click = 1 and cell[2] = 2 then do
			cell_val = grid_list[cell[1]][cell[2]][1]
			
			//Edit a subarray with a recursive array editor
			if TypeOf(cell_val) = "string" and cell_val = "Edit..." then do
				HideDbox()
				edit_sub = RunDbox("Edit Array", Arr[cell[1]])
				ShowDbox()
				if edit_sub <> null then do
					Arr[cell[1]] = edit_sub
				end
			end
			
			//Or, update the value - convert typed numbers to numbers
			else if cell_val <> null then do 
				Arr[cell[1]] = Scen.IO.StrConv(cell_val, )
			end
			
			RunMacro("UpdateGrid")
		end
		
	enditem
	
	button "OK" 1, 22, 10, 1.5 default do
		Return(Arr)
	enditem
	
	button "Cancel" 12, 22, 10, 1.5 cancel do
		Return()
	enditem
	
	

EndDbox

//Dialog box to edit network yeras
// --> Called from IO.EditNetYears
// dbd_file: geographic file to edit
// Opts:
//  --> NoDelete: Network years that cannot be deleted
//  --> YearFields: Link year fields
//  --> YearFieldsN: Node year fields
//  --> Alts: True/False: If True, allow the network to be copied with alternatives
//  --> AltsDefault: True/False: Default setting for copy alternatives (olny used if NetAlts = True)

Dbox "Edit Network Years" (dbd_file, InOpts) , , 21.5, 10.5 

	init do

		shared canned
		shared INI_IDX
		{StageNames, In_Fs, OutFs, Table, Param, DbTab} = Args
		//Create model utilities object
		shared UT
		
		//The following scenarios cannot be deleted
		base_scen = InOpts.NoDelete

		//Passed year fields
		YearFields = InOpts.YearFields
		YearFieldsN = InOpts.YearFieldsN
		
		//Alternative copy functionality options
		if InOpts.Alts then do
			ShowItem("Alternatives")
			if InOpts.AltsDefault then do
				copy_alts = True
			end
		end
		else do
			copy_alts = False
		end
		
		//Add the network to the workspace
		RunMacro("TCB Add DB Layers", dbd_file,,)
		Lyrs = RunMacro("TCB get DB line and node layers", dbd_file)
		node_lyr = Lyrs[1]
		link_lyr = Lyrs[2]

		RunMacro("UpdateYrList")

	enditem //end init
	
	macro "UpdateYrList" do
	
		//Get available network years
		Fields = GetFields(link_lyr, "Integer")
		Fields = Fields[1]
		years1 = null
		for i = 1 to Fields.length do
			left_f = left(Fields[i], 3)
			right_f= substring(Fields[i], 4, )
			if left_f = "FT_" and len(right_f) >= 1 and len(right_f) <= 4 then years1 = years1 + {right_f}
		end
		
		//Check validity of potential years
		years = null
		for i = 1 to years1.length do
			Check = RunMacro("Check NetYear", years1[i], link_lyr, YearFields)
			if Check = years1[i] then do
				years = years + {Check}
			end
		end
		
		years = SortArray(years)
		
		//Set selected item
		if YearIndex = null or YearIndex > years.length then YearIndex = 1
		year_suffix = right(years[YearIndex], 4)
		
		//Check for delete permission
		if ArrayPosition(base_scen, {years[YearIndex]}, ) > 0 or years.Length = 1 then do
			DisableItem("Delete")
		end
		else do
			EnableItem("Delete")
		end
		
	
	enditem

	popdown menu 1, 1, 15, 10 List: years Variable: YearIndex do
		RunMacro("UpdateYrList")
	enditem
	
	button "File" 17.5, 1, .9, 1 prompt: "?" help: "Show network filename" do
		ShowMessage("Current Network File:\n"+dbd_file)
	enditem
	
	checkbox "Alternatives" 1, 2.5 help: "Include alternatives in the copied attributes" variable: copy_alts hidden //only enabled if NetAlts option is True

	button "Copy" 3, 4, 16, 1.5 do

		ask_copy:
		copyto = RunDbox("TextAnswer", "Copy Destination: Enter a 2-4 digit network identifier: ", )

		//Verify value
		if copyto = null or len(copyto) > 4 or Upper(copyto) = "AL" then do
			Opts = null
			Opts.Caption = "Entry Error"
			Opts.Buttons = "RetryCancel"
			ans = MessageBox("Invalid identifier.", Opts)
			if ans = "Retry" then goto ask_copy
			else goto stopNetCopy
		end
	
		//Check for pre-existing value
		if ArrayPosition(years, {copyto},) > 0 then do
			Opts = null
			Opts.Caption = "Entry Error"
			Opts.Buttons = "RetryCancel"
			ans = MessageBox("Network Scenario already exists.", Opts)
			if ans = "Retry" then goto ask_copy
			else goto stopNetCopy
		end
		
		//If selected, ask for alternatives
		if copy_alts then do
			NetAlts = RunDbox("Set Network Alts", {null}, dbd_file)
			if NetAlts = null then goto stopNetCopy
		end

		//ADD LINK FIELDS
		//Read the data to copy
		dim GetVs[YearFields.length]
		for i = 1 to YearFields.length do
			//CopyData[i] = GetDataVector(link_lyr+"|", YearFields[i][1]+"_"+ year_suffix, )
			GetVs[i] = YearFields[i][1]+"_"+ year_suffix
		end
		CopyData = GetDataVectors(link_lyr+"|", GetVs, )
		
		//Define fields to add to the network
		NewFields = null
		for i = 1 to YearFields.length do
			info = GetFieldInfo(link_lyr+"."+YearFields[i][1]+"_"+year_suffix)
   			/*if info[1] = "String" then do
				ShowMessage("Error: Invalid data encountered")
				Return()
			end */                                                                 //width   decimals   join/split copy
			NewFields = NewFields + {{YearFields[i][1]+"_"+copyto, info[1], null,     null,      True}}
		end

		//Determine placement of the new data
		AllFields = GetFields(link_lyr, )
		AllFields = AllFields[1]
		
		BeforeYear = null
		
		for i = 1 to years.length do
			//if new year is less than the current (loop) year,
			if copyto < years[i] then do
				BeforeYear = years[i]
				i = years.length + 1
			end

		end
		
		//If the new year is higher than all existing years,
		if BeforeYear = null then do
			AfterField = YearFields[YearFields.Length][1]+"_"+years[years.length]
			AfterFieldInd = ArrayPosition(AllFields, {AfterField}, )
		end
		else do 
			BeforeField = YearFields[1][1] + "_" + BeforeYear
			AfterFieldInd = ArrayPosition(AllFields, {BeforeField}, ) - 1
		end
			
		if AfterFieldInd < 1 then do
			
			ShowMessage("Cannot update network file - Error sorting link alternatives\n\nERROR: "+string(AfterFieldInd))
			Return()
		end
		AfterField = AllFields[AfterFieldInd]
		
		//Add the fields in the correct order
        UT.AddViewFields(NewFields, link_lyr, AfterField)
		 
		//Copy data from the selected year
		dim SetVs[YearFields.length]
		for i = 1 to YearFields.length do
			//SetDataVector(link_lyr+"|", YearFields[i][1]+"_"+copyto, CopyData[i],)
			SetVs[i] = {YearFields[i][1]+"_"+copyto, CopyData[i]}
		end
		SetDataVectors(link_lyr+"|", SetVs,)
		
		//ADD LINK ALTS
		if NetAlts <> null and (NetAlts.length > 1 or NetAlts[1] <> null) then do
		
			//Select alternative links
			SetView(link_lyr)
			sets = GetSets(link_lyr)
			if ArrayPosition(sets, {"Alts"}, ) > 0 then DeleteSet("Alts")
			for i = 1 to NetAlts.Length do
				cnt = SelectByQuery("Alts", "More", "Select * Where ALT = " + i2s(NetAlts[i]) + " | ALT2 = " + i2s(NetAlts[i]), )
			end
			
			//Set attributes to alternative values
			CreateProgressBar("Set Link Alternative", "True")
			for i = 1 to YearFields.Length do
				//Progress Bar
				prog = r2i(i/YearFields.length * 100)
				canned = UpdateProgressBar("Set Link Alternative", prog)
				if canned then Return()
				//Do not attempt to set feedback speeds to the alternative value
				if YearFields[i][3] = 1 then do
					V = GetDataVector(link_lyr+"|Alts", YearFields[i][1] + "_AL", )
					SetDataVector(link_lyr+"|Alts", YearFields[i][1]+"_"+copyto, V, )
					V = null
				end
			end
			DeleteSet("Alts")
			DestroyProgressBar()
		end

        //ADD NODE FIELDS
		if YearFieldsN <> null then do
			//Read the data to copy
			dim CopyData[YearFieldsN.length]
			for i = 1 to YearFieldsN.length do
				on Error do
					ShowMessage("Error reading node data - Try exporting your database to a new file to remove file corruption.")
					Return()
				end
				CopyData[i] = GetDataVector(node_lyr+"|", YearFieldsN[i][1]+"_"+ year_suffix, )
			end
			
			//Define fields to add to the network
			NewFields = null
			for i = 1 to YearFieldsN.length do
				info = GetFieldInfo(node_lyr+"."+YearFieldsN[i][1]+"_"+year_suffix)
				/*if info[1] = "String" then do
					ShowMessage("Error: Invalid node data encountered")
					Return()
				end*/ 
				NewFields = NewFields + {{YearFieldsN[i][1]+"_"+copyto, info[1]}}
			end 

			//Determine placement of the new data
			AllFields = GetFields(node_lyr, )
			AllFields = AllFields[1]
			
			BeforeYear = null
			for i = 1 to years.length do
				//if new year is less than the current (loop) year,
				if copyto < years[i] then do
					BeforeYear = years[i]
					i = years.length + 1
				end

			end
			
			//If the new year is higher than all existing years,
			if BeforeYear = null then do
				AfterField = YearFieldsN[YearFieldsN.length][1] + "_" + years[years.length]
				AfterFieldInd = ArrayPosition(AllFields, {AfterField}, )
			end
			else do
				BeforeField = YearFieldsN[1][1] + "_" + BeforeYear
				AfterFieldInd = ArrayPosition(AllFields, {BeforeField}, ) - 1
			end
			if AfterFieldInd < 1 then do
					
				ShowMessage("Cannot update network file - Error sorting node alternatives\n\nERROR: "+string(AfterFieldInd))
				Return()
			end
			AfterField = AllFields[AfterFieldInd]
			
			//Add the fields in the correct order
			UT.AddViewFields(NewFields, node_lyr, AfterField)

			//Copy data from the selected year
			for i = 1 to YearFieldsN.length do
				SetDataVector(node_lyr+"|", YearFieldsN[i][1]+"_"+copyto, CopyData[i],)
			end
		
		end //Done copying node year data 
		
		
		YearIndex = 1 //Set to first year in list, since the list has changed
		//End of copy tasks - canceled actions end up here
		stopNetCopy:
		RunMacro("UpdateYrList")

	enditem
	
	button "Delete" same, after, 16, 1.5 do

        //Check for deletion permission
		if ArrayPosition(base_scen, {years[YearIndex]}, ) > 0 or years.Length = 1 then do
			Opts = null
			Opts.Caption = "Stop!"
			Opts.Default = 1
			Opts.Icon = "Stop"
			Opts.Buttons = "OK"
			ans = MessageBox("This scenario cannot be deleted.\nIt is either the base year scenario or the last scenario in this network.", Opts)
			goto stopNetDelete
		end

		//Confirm delete
		Opts = null
		Opts.Caption = "Confirm"
		Opts.Default = 2
		Opts.Buttons = "YesNo"
		ans = MessageBox("Really delete data for " + years[YearIndex] + "?", Opts)
		if ans <> "Yes" then goto stopNetDelete


		//drop link fields
		dim DropFields[YearFields.length]
		for i = 1 to DropFields.length do
			DropFields[i] = YearFields[i][1] + "_" + year_suffix
		end
		UT. DropViewFields(DropFields, link_lyr)
		
		//Drop node fields
		if YearFieldsN <> null then do
			dim DropFields[YearFieldsN.length]
			for i = 1 to DropFields.length do
				DropFields[i] = YearFieldsN[i][1] + "_" + year_suffix
			end
			UT. DropViewFields(DropFields, node_lyr)
		end
		
		YearIndex = 1 //Set to first year in list, since active year was deleted
		//End of copy tasks - canceled actions end up here
		stopNetDelete:
		RunMacro("UpdateYrList")
	EndItem

	button "Close" same, after, 16, 1.5 cancel do
		DropLayerFromWorkspace(link_lyr)
		DropLayerFromWorkspace(node_lyr)
		Return()
	enditem

EndDbox  //End Edit Network Years

Macro "CreateDSN" (Filename)
// This macro creates a DSN file that can be used to read or write data from
// the MS Access database that is passed in the variable Filename.  The returned
// value is the name of a the created DSN file, which is created in the same
// directory as the MS Access *.mdb file.

        //Check for 64-bit version of TransCAD
        p = GetProgram()
        if p.Length >= 7 and p[7] = 64 then 
            dsn_driver = "DRIVER=Microsoft Access Driver (*.mdb, *.accdb)"
        else
            dsn_driver = "DRIVER=Microsoft Access Driver (*.mdb)"
        
		dsn_file = GetTempFilename(".dsn")

		fp = OpenFile(dsn_file, "w")
		WriteLine(fp, "[ODBC]")
		WriteLine(fp, dsn_driver)
		WriteLine(fp, "UID=admin")
		WriteLine(fp, "UserCommitSync=Yes")
		WriteLine(fp, "Threads=3")
		WriteLine(fp, "SafeTransactions=0")
		WriteLine(fp, "PageTimeout=5")
		WriteLine(fp, "MaxScanRows=8")
		WriteLine(fp, "MaxBufferSize=2048")
	//	WriteLine(fp, "FIL=MS Access")
	//	WriteLine(fp, "DriverId=25")
		WriteLine(fp, "DefaultDir=" + file_dir)
		WriteLine(fp, "DBQ=" + Filename)
		CloseFile(fp)

		return(dsn_file)
EndMacro

//Ask Questions:
Dbox "IntAnswer" (Question, Answer)
	title: "  " //Blank title
    //Answer is the default answer
    text 2, 2
     Variable: Question

    edit integer 2, 3.5, 40, 1 Variable: Answer

    button "OK" 30, 5, 8, 1.5 default do
        Return(Answer)
    enditem
EndDbox

//Ask Questions:
Dbox "TextAnswer" (Question, Answer) resize
	title: "  " //Blank title
    //Answer is the default answer
    text 2, 2
     Variable: Question

    edit text 2, 3.5, 40, 1 Variable: Answer resize: width

    button "OK" 27, 5, 8, 1.5 default resize: left do
        Return(Answer)
    enditem
    
    button "Cancel" after, same, 8, 1.5 cancel resize: left do
        Return()
    enditem
    
EndDbox

Macro "TestArr"

	Arr = {10, {20, 30}, 40, 50, 60, 70}
	RunDbox("Edit Array", Arr)
EndMacro

//**************************************************************************
//** Resilient log/report file management
Class "LogManager"  //StartClass
//When created this object will obtain the current log/report filename.  It will reset them
//  when the object is destroyed (obj=null) or goes out of scope.  This means that the log
//  and report filenames will be reset in cases where an error prevents conventional reset
//  lines from being run.  It also resets status bar position 1 to the system message.

    init do
        on error do
            ShowMessage("Log and report filenames appear to be corrupt. Please restart TransCAD")
            Return()
        end
        self.OrigReport = GetReportFileName()
        self.OrigLog = GetLogFileName()
        on error default
    enditem
    
    macro "Reset" do //Allow both to be quickly reset.
        SetReportFileName(self.OrigReport)
        SetLogFileName(self.OrigLog)
    enditem
    
    done do
        SetReportFileName(self.OrigReport)
        SetLogFileName(self.OrigLog)
        SetStatus(1, "@System0", )
    enditem


EndClass

//Hide a dbox, but show it again even if something unexpected happens
Class "HideBox" (ui_file, dBoxName)

    init do
        self.HidBox = False
        self.Name = dBoxName
        self.ui = ui_file
    
        //on NotFound goto NoHide
        SetAlternateInterface(self.ui)
        HideDbox(self.Name)
        SetAlternateInterface()
        self.Hid = True
        NoHide:
    enditem
    
    done do
        if self.Hid then do
            SetAlternateInterface(self.ui)
            ShowDbox(self.Name)
            SetAlternateInterface()
        end
    enditem

EndClass