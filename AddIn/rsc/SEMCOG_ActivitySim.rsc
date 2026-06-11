// ************ ACTIVITYSIM REVISION HISTORY **************
// Starting February 2020, RSG started making adjustments to the E7 script for ActivitySim deployment.
// This inlcuded updating the highway and transit skimming process. RSG also added a non-motorized skimming macro.

Macro "SEMCOG Model Version"
    project_version_string = "ActSim V1.3 - June 30, 2026"
    required_tc_build   = 22365
    required_tc_version = 8.0
    return({project_version_string, required_tc_build, required_tc_version})
EndMacro

// *****************************************************************************
// Define default macro and step names
Macro "SEMCOG Model Steps" (Scen)

    //names of stages, must match names of buttons in dialog box.
    Scen.StageNames = {"Initialization",
                       "Network Skimming",
                       "External and Airport Models",
					   "ActivitySim",
                       "Commercial Vehicle",
                       "Trip Assignment"}
    Scen.StageIndex = {"INI", "SKM", "EXT", "ABM", "CVM", "ASN", "RPT"}

    //Macros to run for each step
    Scen.StepMacro = {{"SEMCOG Update Directory", "Export Network Data", "Process Land Use Data", "SEMCOG Highway Process",
                       "SEMCOG Transit Process", "SEMCOG Build Highway Network",
                       "SEMCOG Build Transit Network"},

                      {"SEMCOG Highway Skimming", "SEMCOG Non Motorized Skimming", "SEMCOG PR Access",
                       "SEMCOG Transit Skims", "SEMCOG Process Transit Skims"},

                      {"Airport Model", "EI Model", "IE Model"},

					   //{"Synthetic Population Processing", "Landuse Processing", "ActivitySim"}, //uncomment if running synthetic population processor, and comment out the next line
					  {"ActivitySim Preprocessing", "ActivitySim", "ActivitySim Postprocessing", "Visualizer"},

                      {"SEMCOG CV Firm Synthesis", "SEMCOG CV Long Distance Model",
		               "SEMCOG CV Touring Model", "SEMCOG CV Trip Tables",
					   "SEMCOG CV Dashboard"},

                      {"SEMCOG EA Highway Assignment", "SEMCOG AM Highway Assignment",
                       "SEMCOG MD Highway Assignment", "SEMCOG PM Highway Assignment",
                       "SEMCOG EV Highway Assignment", "SEMCOG Assignment Combine",
                       "SEMCOG Transit Assignment", "SEMCOG Transit Combine",
                       "SEMCOG Feedback"}}


    //Percentage of model progress, to go with above:
    Scen.StepProg = null
    for ii = 1 to Scen.StepMacro.length do
        dim a[Scen.StepMacro[ii].length]
        min_prog = R2I((ii-1) / Scen.StepMacro.length * 100)
        max_prog = R2I(ii / Scen.StepMacro.length * 100)
        diff_prog = max_prog-min_prog
        for jj = 1 to Scen.StepMacro[ii].length do
            a[jj] = R2I(min_prog + (diff_prog*jj/Scen.StepMacro[ii].length))
        end
        Scen.StepProg = Scen.StepProg + {CopyArray(a)}
    end

    //Steps to run by default:
    // --> Used to quickly turn certain steps off for debugging
    // --> 1 = run by default
    // --> 0 = do not run by default
    // --> -1 = Disabled
    Scen.StepSwitch={{1, 1, 1, 1, 1, 1, 1},                 //INI
                     {1, 1, 1, 1, 1},                       //SKM
					 {1, 1, 1}, 							//EXT
					 {1, 1, 1, 1},								//ActivitySim
                     {1, 1, 1, 1, 1},                   //CVM
                     {1, 1, 1, 1, 1, 1, 1, 1, 1}}     //ASN

    //Set feedback loops to run
    // 0 = Run only on the first loop
    // 1 = Always run
    // 2 = Run only on the final loop -- ONLY VALID AFTER DST due to in-loop RMSE check
    Scen.StepFeedback = {{0, 0, 0, 0, 1, 1, 1},             //INI
                         {1, 1, 1, 1, 1},                   //SKM
                         {1, 1, 1},                         //Airport External
						 {1, 1, 1, 2},                      //ABM
                         {0, 0, 1, 1, 2},                   //CVM
                         {2, 1, 1, 1, 2, 2, 2, 2, 1}} //ASN

	//Disable settings (based on 1/0/-1 in StepSwitch)
    Scen.StepDisable = CopyArray(Scen.StepSwitch)
    for i = 1 to Scen.StepDisable.length do
        for j = 1 to Scen.StepDisable[i].length do
            Scen.StepDisable[i][j] = (if Scen.StepSwitch[i][j] = -1 then 1 else 0)
            Scen.StepSwitch[i][j] = (if Scen.StepSwitch[i][j] = -1 then 0
                                     else Scen.StepSwitch[i][j])
        end
    end

    Return(1)
EndMacro

DBox "SEMCOG Model"
    Location: SEMCOG_x, SEMCOG_y
    toolbox NoKeyboard resize
    title: "SEMCOG Planning Model"

    Init do //StartMethod
        Shared  model_ui, scen_data_dir, ui_dir,
                nOper, TransCADVersion, Period, Purpose, run_DestinationChoice, run_CriticalLinkAnalysis

        //Define location and selected scenario
        //Dialog box will be right-center, but will remember its location
        static SEMCOG_x, SEMCOG_y, SEMCOG_ScenFlag, SEMCOG_tab
        if SEMCOG_x = null then SEMCOG_x = -3

		Period = {"EA", "AM", "MD", "PM", "EV"}
		Purpose = {"HBW_Low", "HBW_High", "HBU", "HBO_HBSH", "NHBW_NHBO", "HBSch"}


        RegInfo = RunMacro("Get Registration Info")
        TransCADVersion = s2r(RegInfo.VersionNum)

        //File locations
        model_ui = GetInterface() //Location of compiled UI file (must be a user-writable folder)
        tmp = SplitPath(model_ui)
        ui_dir = tmp[1] + tmp[2]

        //Initialize scenario manager variables
		shared Scen
		Scen = null
        Scen.Vars.[Model Name] = "SEMCOG"
        Scen.Vars.Simplified = True //Run with simplified Args for compatibility with Caliper scneario manager
        Scen.Vars.scenui_file = ui_dir + "scen_ui.dbd"  //Compiled scenario manager
        Scen.Vars.utilui_file = ui_dir + "util_ui.dbd"  //Compiled helper utilities
        Scen.Vars.dashui_file = ui_dir + "dash_ui.dbd"  //Compiled dashboard / mapper
        Scen.Vars.sumui_file = ui_dir + "report_ui.dbd"  //Compiled summary report
        Scen.Vars.interop_file = ui_dir + "interop_ui.dbd"  //Compiled interoperability reports
        Scen.Vars.defscen_file = ui_dir + "DefaultScenario.ini" //Default scenario definition
        Scen.Vars.scenario_file = ui_dir + "Scenarios.arr" //Scenario array filename (default value)
        Scen.Vars.scenptr_file = ui_dir + "ScenarioFilename.txt" //File that contains saved current scenario filename
        Scen.Vars.scenario_dir = {"C:\\SEMCOG\\ScnearioName\\Input\\", "C:\\SEMCOG\\ScenarioName\\Output\\"}   //Default scenario directory (used on first run only)

		//Create scenario I/O utilities object
        SetAlternateInterface(Scen.Vars.scenui_file)
		Scen.IO = CreateObject("Scen.IO")
        SetAlternateInterface()

		//Create model utilities object
		shared UT
		UT = null
        SetAlternateInterface(Scen.Vars.utilui_file)
		UT = CreateObject("Utilities")
        SetAlternateInterface()

        //Create dashboard mapper object
        shared MP
        MP = null
        SMP = null
        SetAlternateInterface(Scen.Vars.dashui_file)
		MP = CreateObject("Mapper")
        SMP = CreateObject("Mapper") //Separate mapper for select link/zone to prevent conflicts with other maps
        SetAlternateInterface()

        //Create performance report object
        Scen.Perf = null
        SetAlternateInterface(Scen.Vars.sumui_file)
        Scen.Perf = CreateObject("Performance", util_args)
        SetAlternateInterface()

        //Load static ScenFlag if exists
        if SEMCOG_ScenFlag != null then Scen.Vars.ScenFlag = SEMCOG_ScenFlag

		//Load default scenario from file
		Scen.Vars.DefArgs = Scen.IO.ReadINI(Scen.Vars.defscen_file, True, )

        //Call scenario toolbox
        SetAlternateInterface(Scen.Vars.scenui_file)
		Scen.Control = CreateObject("Scen.Control")
        SetAlternateInterface()
        Scen.Vars.CheckLimit = 1
        Scen.Control.UpdateList() //Load the scenario file (or create a new file)

        //Get model step info
        RunMacro("SEMCOG Model Steps", &Scen)

        //Default checkbox settings
        Scen.CreatePerf = 0
        static SEMCOG_StopStage //Remember between sessions
        if SEMCOG_StopStage then do
            Scen.StopStage = 1
            Scen.CreatePerf = 0 //set to zero here, in case default is changed to 1
            HideItem("report")
        end else do
            Scen.StopStage = 0
        end

        //Debug off by default
        Scen.Vars.DebugMode = False

        //Items to enable only when the run is ready or complete
        EnableWhenReady = {"Mode Choice Calibration", "Destination Choice Calibration"}
        EnableWhenComplete = {"Summary Report", "TrafficCreate"}



        //Set up file templates
        //!!! These need to match noted Args values
        Scen.ExpandSettings.PER_PK = {"PK", "OP"}  //Args.PkOpPeriods
        Scen.ExpandSettings.PER_PK2 = {"AM", "MD"} //Args.PkOpPeriods2
        Scen.ExpandSettings.PER_HWY = {"EA", "AM", "MD", "PM", "EV"} //Args.HwyPeriods
        Scen.ExpandSettings.PER_TRN = {"EA", "AM", "MD", "PM", "EV"}       //Args.TrnPeriods
        Scen.ExpandSettings.PURP = {"HBW", "HBO", "HBSH", "HBSc", "HBU", "NHBW", "NHBO"}
		Scen.ExpandSettings.SCEN_NAME = Args.Info.Name
        Scen.ExpandSettings.INC_SEG = {"INC1", "INC2", "INC3"}         //Args.IncSegs
        Scen.ExpandSettings.VEH_SEG = {"VEH1", "VEH2", "VEH3"}         //Args.VehSegs

        Scen.ExpandSettings.TMODE = {"LOC", "PRM", "MIX"}
        Scen.ExpandSettings.AMODE  = {"WLK", "DRV", "KNR", "DRVE", "KNRE"}

        //get version info
        VerInfo = RunMacro("SEMCOG Model Version")

        //Final file check
        Scen.Vars.CheckLimit = null
        Scen.Control.UpdateList() //Load the scenario file (or create a new file)
        Scen.Vars.CheckLimit = 2

        //Update dialog box details
        RunMacro("Update")

    enditem //EndMethod

    update do //StartMethod
        RunMacro("Update")
    enditem //EndMethod

    //Update the dialog box to enable and disable items based on scenario completeness
    Macro "Update" do

        FC = Scen.Control.CheckFiles()

        for ii = 1 to FC.StepStatus.length do
            button_name = 'semcog' + String(ii)
            if Scen.Vars.DebugMode or FC.StepStatus[ii] then do
                EnableItem(button_name)
            end else do
                DisableItem(button_name)
            end
        end

        //Enable/disable other buttons
        for itm in EnableWhenReady do
            if Scen.Vars.DebugMode or FC.RunReady then do
                EnableItem(itm)
            end else do
                DisableItem(itm)
            end
        end

        for itm in EnableWhenComplete do
            if Scen.Vars.DebugMode or FC.RunComplete then do
                EnableItem(itm)
            end else do
                DisableItem(itm)
            end
        end

        //Update the dashboard as well
        RunMacro("UpdateDash")

    enditem
    //EndMethod

    close do Runmacro("closing") endItem

    //StartMethod - Dbox Header
    sample "Logo" 0, 0, 37, 5 transparent
    contents: SamplePoint("Color Bitmap",
                          ui_dir + "bmp\\SEMCOG.bmp", 51, , ) //Size here works with better with high-res displays

    //Quit Button and version (on all tabs)
    button 1, 39, 35, 1.7 prompt: "Quit" resize: top, width do Runmacro("closing") endItem
    text  1, after, 37 Variable: VerInfo[1] align: center resize: top, width


    //EndMethod
    //StartMethod ****** Scenario Selection Area ******

    scroll list  .5, 5.5, 36.5, 11 List: Scen.Vars.ScrNameList Multiple Variables: Scen.Vars.ScenFlag, dclick  resize: height, width
        help: "Double-click on a scenario to view and edit the contents"
    do
        if dclick = 0 then do
            Scen.Control.UpdateList()
        end //end single click action
        else do //for a double click only
            if Scen.Vars.ScenFlag.length = 1 then do //Open the scenario manager if only one is selected
                Scen.Control.Manage()
                Scen.Control.UpdateList()
            end
        end
        RunMacro("Update")
    enditem

    button "Add" 2, 17 help: "Add a new scenario using the default scenario settings" resize: top icon: "bmp\\Tools01|2" do
		//new_scenario_dir = {Args.Info.[Input Directory], Args.Info.[Output Directory]} //Use the currently selected scenario
		Scen.Control.AddScen()
        Scen.Vars.ScenFlag = {Scen.Vars.ScrNameList.Length + 1}  //Select the newly added scen (at end of list)
        Scen.Control.UpdateList()
        RunMacro("Update")
    EndItem

    button "Copy" after, same help: "Make a copy of the selected scenario" icon: "bmp\\MiscButtons|3" resize: top do
        if Scen.Vars.ScenFlag.length > 1 then do
            ShowMessage("Only one scenario can be copied at a time")
        end
        else do
			Scen.Control.CopySelected()
            ScenFlag = {Scen.Vars.ScrNameList.Length + 1}  //Select the newly added scen (at end of list)
            Scen.Control.UpdateList()         //Update with new scenario info
            RunMacro("Update")
        end
    EndItem

    button "Delete" after, same help: "Delete the selected scenario(s)" resize: top icon: "bmp\\Tools01|7" do

		if Scen.Vars.ScenFlag.Length = 1 then message = "Are you sure you wish to delete this scenario?"
		else message = "Are you sure you wish to delete the " + string(Scen.Vars.ScenFlag.Length) + " selected scenarios?"
        if Scen.Arr.length = 1 or Scen.Arr.length = Scen.Vars.ScenFlag.length then
            ShowMessage("Cannot Delete Last Remaining Scenario")
		else if RunDbox("G30 Confirm", message) = "Yes" then do
			Scen.Control.DeleteSelected()
		end //end if confirmed delete
		Scen.Control.UpdateList()
        RunMacro("Update")
    endItem //delete button

    button "Move Up" 17, same icon: "bmp\\Tools01|56" resize: top do
        //Adjust arrays
		Scen.Control.MoveSelection("Up")
        RunMacro("Update")
    EndItem //Move up button

    button "Move Down" after, same icon: "bmp\\Tools01|51" resize: top do
        //Adjust arrays
		Scen.Control.MoveSelection("Down")
        RunMacro("Update")
    EndItem  //Move down button

    checkbox "Debug" 30, same variable: Scen.Vars.DebugMode help: "Run model in debug mode" prompt: null

    button "Args" after, same icon: "bmp\\DataviewLayoutButtons|20" resize: top, left
        help: "Show the Argument array details for the selected scenario (for troubleshooting and debugging)" do

        ShowArgs = null
        for _scen = 1 to Scen.Vars.ScenFlag.length do
            scenario_name = Scen.Arr[Scen.Vars.ScenFlag[_scen]][1]
            ShowArgs.(scenario_name) = CopyArray(Scen.Arr.(scenario_name))
        end

        UT.ShowValue(ShowArgs)
    enditem

    tab list 1, 19, 36, 19.5 resize: top, width variable: SEMCOG_tab
    //EndMethod ****** Scenario Selection Area ******
    //StartMethod ****** Run Buttons ******

    tab "Run" prompt: "Run Model"

    checkbox "stops" 12, 1, 15 variable: Scen.StopStage prompt: "Stop after stages" resize: top do
        SEMCOG_StopStage = Scen.StopStage
        if Scen.StopStage then do
            Scen.CreatePerf = 0
            HideItem("report")
        end else do
            ShowItem("report")
        end
    enditem
    checkbox "report" 12, 2.5, 15 variable: Scen.CreatePerf prompt: "Create Report" help: "Create a summary report when model run completes" resize: top do
        if Scen.CreatePerf then do
            stg = Scen.Perf.GetSettings()
            if !stg then Scen.CreatePerf = 0
        end
    enditem

    button "AllSteps" 1, 1 icon: "bmp\\plan_config_v3.bmp" resize: top help: "Step settings for all steps" do
        Scen.Control.AllSteps()
    enditem

    button "sem_b1" 1, 4.5 icon: "bmp\\plan_config_v2.bmp" resize: top do Scen.Control.SubSteps(1) enditem
    //!!! works better with high res displays, but platform displays with black border
    //!!! sample button "sem_b1" 1, 4.55, 7.5, 1.3 Contents: SamplePoint("Color Bitmap", "bmp\\plan_config_v2.bmp", 18, , ) resize: top do Scen.Control.SubSteps(1) enditem
    button "semcog1" After, 4.5, 23, 1.4 prompt:Scen.StageNames[1] resize: top, width do Scen.Control.RunModel(1) endItem

    button "sem_b2" 1, 6.5 icon: "bmp\\planskim_v2.bmp" resize: top do Scen.Control.SubSteps(2) enditem
    button "semcog2" After, same, 23, 1.4 prompt:Scen.StageNames[2] resize: top, width do Scen.Control.RunModel(2) endItem

    button "sem_b3" 1, 8.5 icon: "bmp\\planmodesplit_v2.bmp" resize: top do Scen.Control.SubSteps(3) enditem
    button "semcog3" After, same, 23, 1.4 prompt:Scen.StageNames[3] resize: top, width do Scen.Control.RunModel(3) endItem

    button "sem_b4" 1, 10.5 icon: "bmp\\planassign_v2.bmp" resize: top do Scen.Control.SubSteps(4) enditem
    button "semcog4" After, same, 23, 1.4 prompt:Scen.StageNames[4] resize: top, width do Scen.Control.RunModel(4) endItem

    button "sem_b5" 1, 12.5 icon: "bmp\\planmodesplit_v2.bmp" resize: top do Scen.Control.SubSteps(5) enditem
    button "semcog5" After, same, 23, 1.4 prompt:Scen.StageNames[5] resize: top, width do Scen.Control.RunModel(5) endItem
	//
    button "sem_b6" 1, 14.5 icon: "bmp\\planassign_v2.bmp" resize: top do Scen.Control.SubSteps(6) enditem
    button "semcog6" After, same, 23, 1.4 prompt:Scen.StageNames[6] resize: top, width do Scen.Control.RunModel(6) endItem



    //EndMethod ****** Run Buttons ******
    //StartMethod ****** Utilities ******
    tab "Utilities" prompt: "Utilities"

    frame "ReportTools" 1, 0.5, 33, 8 Prompt: "Reporting Tools" resize: top, width

    button "Summary Report" 3, 2, 29, 1.5 resize: top, width do
        //Only one scenario can be selected
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Summary reporting requires that one and only one scenario is selected.")
        end else do
            HideDbox()
            util_scen = Scen.Vars.ScenFlag[1]
            util_args = Scen.Control.Simplified(Scen.Arr[util_scen][2])

            //Add complete Args array for file/param summary
            Scen.Perf.SetArgs(util_args)
            Scen.Perf.Args2 = Scen.Arr[util_scen][2]

            res = Scen.Perf.GetSettings()
            if res != null then Scen.Perf.CreateReport()

            ShowDbox()
        end

    enditem

    button "AQ" 3, 4.5, 14, 1.4 do
        //Only one scenario can be selected
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Summary reporting requires that one and only one scenario is selected.")
        end else do
            util_scen = Scen.Vars.ScenFlag[1]
            util_args = Scen.Control.Simplified(Scen.Arr[util_scen][2])
            SetAlternateInterface(Scen.Vars.interop_file)
            HideDbox()
            RunDbox("SEMCOG AQ", util_args)
            ShowDbox()
            SetAlternateInterface()
        end
    enditem

    button "EJ" after, 4.5, 14, 1.4 do
        //Only one scenario can be selected
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Summary reporting requires that one and only one scenario is selected.")
        end else do
            util_scen = Scen.Vars.ScenFlag[1]
            util_args = Scen.Control.Simplified(Scen.Arr[util_scen][2])
            SetAlternateInterface(Scen.Vars.interop_file)
            HideDbox()
            RunMacro("SEMCOG EJ", util_args)
            ShowDbox()
            SetAlternateInterface()
        end
    enditem

    button "ActivitySim Input Checker" 3, 7, 29, 1.5 resize: top, width do
        //Only one scenario can be selected
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Input Checker requires that one and only one scenario is selected.")
        end else do
            HideDbox()
            util_scen = Scen.Vars.ScenFlag[1]
            util_args = Scen.Control.Simplified(Scen.Arr[util_scen][2])

            //Add complete Args array for file/param summary
            Scen.Perf.SetArgs(util_args)
            Scen.Perf.Args2 = Scen.Arr[util_scen][2]
            RunMacro("ActivitySim Input Checker", util_args)
            ShowDbox()
            SetAlternateInterface()
        end

    enditem

    frame "CalibTools" 1, 9.5, 33, 3.5 Prompt: "Calibration Tools" resize: top, width

    button "Mode Choice Calibration" 3, 11, 14, 1.5 prompt: "Mode Choice" resize: top, width do
        //Only one scenario can be selected
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Mode Choice Calibration requires that one and only one scenario is selected.")
        end else do
            HideDbox()
            util_scen = Scen.Vars.ScenFlag[1]
            util_args = Scen.Control.Simplified(Scen.Arr[util_scen][2])
            RunMacro("SEMCOG Mode Choice Calibration", util_args)
            ShowDbox()
        end

    enditem

    button "Destination Choice Calibration" after, same, 14, 1.5 prompt: "Dest Choice" resize: top, width do
        //Only one scenario can be selected
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Trip distribution Calibration requires that one and only one scenario is selected.")
        end else do
            HideDbox()
            util_scen = Scen.Vars.ScenFlag[1]
            util_args = Scen.Control.Simplified(Scen.Arr[util_scen][2])
            RunDbox("DC Calibration", util_args)
            ShowDbox()
        end

    enditem

    button 3, 14, 29, 1.5 prompt: "Other Utilities" resize: top, width do RunDBox("SEMCOG Utilities", ScenSel, ScenArr) endItem


    //Button for testing of a given macro/task using a single scenario
    /*
    button "TEST" 1, 15, 25, 1.5 do
        //Only one scenario can be selected
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("TEST requires that one and only one scenario is selected.")
        end else do

            //get args
            test_scen = Scen.Vars.ScenFlag[1]
            test_args = Scen.Control.Simplified(Scen.Arr[test_scen][2])

            //Test code goes here
            //-------------------

            //...

            //-------------------


        end
    enditem
    */



    //EndMethod ****** Utilities ******

    //StartMethod ****** Dashboard ******
    tab "Dashboard" prompt: "Dashboard"


   //StartMethod //Traffic Map type selection
    //Traffic Maps

    radio list "Traffic Maps" 0.5, 1, 33.5, 15 variable: MP.TrafficMap.Type prompt: "Traffic Maps" resize: top

    radio button "Validation" 2, 2.5 resize: top do RunMacro("UpdateDash") enditem         //1
    radio button "Volume" same, after resize: top do RunMacro("UpdateDash") enditem        //2
    radio button "LOS" same, after resize: top hidden do RunMacro("UpdateDash") enditem    //3 - Not available for this model
    radio button "Select Link/Node" same, after resize: top hidden do RunMacro("UpdateDash") enditem  //4 - Moved to a different frame
    radio button "Comparison" 15, 2.5 resize: top do RunMacro("UpdateDash") enditem  //5
    radio button "Volume/Capacity" same, after resize: top do RunMacro("UpdateDash") enditem //6


    //EndMethod
    //StartMethod //Traffic Map options




    checkbox "Thousands" 2, 6 resize: top
             variable: MP.TrafficMap.Opts.Thousands
             help: "Label volumes in thousands of vehicles" do
        MP.TrafficMap.Save.Thousands  = MP.TrafficMap.Opts.Thousands
    enditem
    checkbox "Volumes" same, after resize: top
             variable: MP.TrafficMap.Opts.Volumes
             help: "Include volume labels on the map" do
        MP.TrafficMap.Save.Volumes  = MP.TrafficMap.Opts.Volumes
    enditem
    checkbox "Connectors" same, after resize: top
             variable: MP.TrafficMap.Opts.Connectors
             help: "Show centroid connectors on the map" do
        MP.TrafficMap.Save.Connectors = MP.TrafficMap.Opts.Connectors
    enditem
    checkbox "Big Labels" same, after resize: top
             variable: MP.TrafficMap.Opts.[Big Labels]
             help: "Use larger labels for on-screen viewing" do
        MP.TrafficMap.Save.[Big Labels] = MP.TrafficMap.Opts.[Big Labels]
    enditem

    checkbox "Highlight" 15, 6 resize: top
             variable: MP.TrafficMap.Opts.Highlight
             help: "Highlight high/low volumes" do
        MP.TrafficMap.Save.Highlight = MP.TrafficMap.Opts.Highlight
    enditem
    checkbox "Label Connectors" same, after resize: top
             variable: MP.TrafficMap.Opts.[Label Connectors]
             help: "Show labels oncentroid connectors" do
        MP.TrafficMap.Save.[Label Connectors] = MP.TrafficMap.Opts.[Label Connectors]
    enditem

    //!!! Not relevant for this model, so hidden
    checkbox "Input Network" same, after hidden resize: top
             variable: MP.TrafficMap.Opts.[Input Network]
             help: "Create the map using the input geographic file" do
        MP.TrafficMap.Save.[Input Network] = MP.TrafficMap.Opts.[Input Network]
    enditem

    //!!! Not enabled for this model, so hidden
    checkbox "NCHRP" same, after hidden resize: top
             variable: MP.TrafficMap.Opts.NCHRP
             help: "Create map using NCHRP-255 Adjusted daily volumes" do
        MP.TrafficMap.Save.NCHRP = MP.TrafficMap.Opts.NCHRP
    enditem

    popdown menu "Period" 20, 13, 10, 7 List: MP.Periods resize: top
                 variable: MP.TrafficMap.Opts.Period
                 help: "Traffic assignment time period" do
        MP.TrafficMap.Save.Period = MP.TrafficMap.Opts.Period
		RunMacro("Update")
    enditem

    //EndMethod //Traffic Map Options


    //Update the dashboard dialog box to enable and disable items as needed for
    //  each map
    Macro "UpdateDash" do

        //Enable and disable options
        MapDisable = MP.TrafficMap.Disable.(MP.TrafficMap.MapNames[MP.TrafficMap.Type])

        for i = 1 to MP.TrafficMap.Settings.Length do
            s = MP.TrafficMap.Settings[i]

            if MapDisable.(s) != null then do
                DisableItem(s)
                MP.TrafficMap.Opts.(s) = MapDisable.(s)
            end
            else do
                EnableItem(s)
                MP.TrafficMap.Opts.(s) = MP.TrafficMap.Save.(s)
            end
        end

        //Set up Args for the mapper
        dash_scen = Scen.Vars.ScenFlag[1]
        dash_args = Scen.Control.Simplified(Scen.Arr[dash_scen][2])
        MP.SetScenario(dash_args)
        SMP.SetScenario(dash_args)

        //Select link/zone map disable
        SelDisable = {"SelQry", "SelPer", "SelectType", "SelConnectors", "SelLabels", "SelectCreate"}
        if SMP.SelList = null then do
            for s in SelDisable do
                DisableItem(s)
            end

        end else do
            for s in SelDisable do
                EnableItem(s)
            end
        end

		//Time period: Disable NCHRP adjustment unless daily
        //!!! Not enabled for this model
		//if MP.TrafficMap.Opts.Period > 1 then do
		//	MP.TrafficMap.Opts.NCHRP = 0
		//	DisableItem("NCHRP")
		//end else do
		//	MP.TrafficMap.Opts.NCHRP = MP.TrafficMap.Save.NCHRP
		//end

    EndItem
    //EndMethod

    //StartMethod //Traffic Map Create button
    button "TrafficCreate" 2, 13, 15, 1.5 prompt: "Create" resize: top do
        HideDbox()

        //Verify that only one scenario is selected.
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Dashboard functions require that one and only one scenario is selected.")
            goto nomap
        end

        //Set up Args for the mapper
        dash_scen = Scen.Vars.ScenFlag[1]
        dash_args = Scen.Control.Simplified(Scen.Arr[dash_scen][2])
        MP.SetScenario(dash_args)


        //If using NCHRP adjustment, set adj variable
        //(not enabled for this model)
        //if MP.TrafficMap.Opts.NCHRP then adj = "_NCHRP"
        //else adj = ""
        adj = ""

        //Set thousands divisor (must be strings)
        if MP.TrafficMap.Opts.Thousands then do
            vol_denom = '1000'
        end else do
            vol_denom = '1'
        end

        //If running select link, ask for settings
        if MP.TrafficMap.Type = 4 then do
            SelOpts = MP.SelectMapSettings(dash_args.[Crit_Query])
            if SelOpts = null then goto nomap
            sel_qry = SelOpts.QueryName
        end

        //If running a comparison, ask for a scenario
        if MP.TrafficMap.Type = 5 then do //Traffic comparison
            comp_flow = MP.GetScenario(MP.Periods[MP.TrafficMap.Opts.Period])
            if comp_flow = null then goto nomap
        end

        //If running validation, check for allowable period and set count field
        if MP.TrafficMap.Type = 1 then do
            val_pers = {"AM", "PM", "DY"}
            per_name = MP.Periods[MP.TrafficMap.Opts.Period]
            if ArrayPosition(val_pers, {per_name}, ) = 0 then do
                ShowMessage("Validation map can only be created for the following time periods:\n"+JoinStrings(val_pers, ', '))
                goto nomap
            end

            if per_name = "DY" then MP.count_field = "MAP_COUNT"
            else MP.count_field = "TOT_COUNT_"+per_name

        end

        //Initialize map
        MP.Files.Zones = taz_file
        MP.Scope = def_scope
        MP.MapName = MP.TrafficMap.MapNames[MP.TrafficMap.Type]
        if MP.TrafficMap.Opts.[Input Network] then do
			MP.Create(MP.[DBD File], True) //True= don't redraw map
		end
		else MP.Create(MP.[DBD File], True) //True= don't redraw map

        //Select centroid connectors (optionally show them)
        MP.Connectors(conn_qry, MP.TrafficMap.Opts.Connectors)
        //Select links to hide (always hide them)
        MP.HideLinks(hide_qry, True)

        //Identify and join the flow file
        flow_file = MP.FlowList[MP.TrafficMap.Opts.Period]
        MP.JoinFlows(flow_file, True)

        //*** Replace link themes ***

        //Add bandwidth and LOS theme if enabled
        if MP.TrafficMap.Type = 3 then do
            MP.ClearThemes(MP.Layers.Links)
            MP.Bandwidths(MP.Views.NetFlow+".TOT_Flow"+adj,
                          {{"Data Source", "Screen"}})
            MP.LOS("LOS_MAP"+adj)
        end
        //Select link/node
        else if MP.TrafficMap.Type = 4 then do
            MP.ClearThemes(MP.Layers.Links)
            MP.Bandwidths(MP.Views.NetFlow+'.AB_Flow_'+sel_qry,
                          {{"Data Source", "Screen"}})

        end
        //Or, add a traffic comparison theme
        else if MP.TrafficMap.Type = 5 then do //Traffic comparison
            MP.ClearThemes(MP.Layers.Links)
            MP.CompareFlows(comp_flow, 5)
        end
        //V/C map
        else if MP.TrafficMap.Type = 6 then do
            MP.ClearThemes(MP.Layers.Links)
            MP.Bandwidths(MP.Views.NetFlow+".TOT_Flow",
                          {{"Data Source", "All"},
                           {"Line Style", "Solid"}})

            CreateExpression(MP.Views.NetFlow, "AB_MVOC",
                             "AB_VOC", )
            CreateExpression(MP.Views.NetFlow, "BA_MVOC",
                             "BA_VOC", )
            CreateExpression(MP.Views.NetFlow, "TOT_MVOC",
                             "Max(nz(AB_MVOC), nz(BA_MVOC))", )

            MP.VOC("TOT_MVOC")

            SetLineColor(MP.Layers.Links+"|CentroidConnectors",
                         MP.Colors("LtGray"))
        end
        else do
            //Default to the FT Theme, but use the default FT field (FT)
            //rather that a year-based FT theme
            MP.FTTheme()
        end

        //Add link labels if active
        if MP.TrafficMap.Type = 1 then do
            exp_priority = "(if nz("+MP.count_field+") > 1 then (9000 - 100*FT) + Length else " +
                        "(1000 - 100*FT) + Length)"
        end else do
            exp_priority = "(1000 - 100*FT) + Length"
        end
        Opts = null
        Opts.[Priority Expression] = exp_priority
        if !MP.TrafficMap.Opts.[Label Connectors] then Opts.CC.Expression = 'null'
		if MP.TrafficMap.Opts.[Big Labels] then do
			Opts.Font = "Arial|12"
			Opts.CC.Font = "Arial|10"
		end
        if MP.TrafficMap.Type = 1 then do //Validation

            exp_validation = '(Format(TOT_Flow/'+vol_denom+', "*.") + ' +
                            'if '+MP.count_field+' > 0 then "(" + ' +
                            'Format('+MP.count_field+'/'+vol_denom+', "*.") + ")")'

            //Join counts to the network
            //!!! Non-standard, counts in a separate file instead of on the network
            count_file = dash_args.[Count Table]
            t = SplitPath(count_file)
            count_vw = OpenTable(t[3], "FFB", {count_file})
            join_vw = UT.AttachCounts(MP.Views.NetFlow, count_vw)

            Opts.Highlight = MP.TrafficMap.Opts.Highlight
            Opts.ExpressionView = join_vw //!!! separate view for counts
            exp = exp_validation

            MP.Label(exp, Opts)
        end
        else if MP.TrafficMap.Type = 5 then do
            Opts.ExpressionView = MP.Views.NetCompareFlow
            MP.Label('if DIFFCOLOR = 0 then null ' +
                     'else Format(ABSDIFF/'+vol_denom+', "*.0")', Opts)
        end
        else if MP.TrafficMap.Opts.Volumes then do //Non-validation
			if MP.TrafficMap.Opts.Period = 1 then
				exp = 'Format(TOT_Flow'+adj+'/'+vol_denom+', "*.")'
			else
				exp = 'Format(TOT_Flow'+adj+'/'+vol_denom+', "*.0")'
            MP.Label(exp, Opts)
        end

		//Make read only if not input network
        /* Only relevant in a model with separate input/ouptut files
		CurrentViews = GetViews()
		CurrentViews = CurrentViews[1]
		if !MP.TrafficMap.Opts.[Input Network] then do
			for _lyr = 1 to MP.Layers.length do
				lyr = MP.Layers[_lyr][2]
				if ArrayPosition(CurrentViews, {lyr}, ) > 0 then
					SetViewReadOnly(lyr, "True")
			end
			for _vw = 1 to MP.Views.length do
				vw = MP.Views[_vw][2]
				if ArrayPosition(CurrentViews, {vw}, ) > 0 then
					SetViewReadOnly(vw, "True")
			end

		end
        */

        MP.Redraw()
        SetMapRedraw(MP.Map, "True")


        //If a validation map, show the separate validation map toolbox
        // and exit this dbox
        if MP.TrafficMap.Type = 1 then do
            MP.LabelingToolbox()
        end

		if MP.TrafficMap.Type = 5 then do
            MP.LabelingToolbox()
        end


        //If Canceled, we will skip to here
        nomap:


        ShowDbox()

    enditem
    //EndMethod

    //EndMethod ****** Dashboard ******


    //StartMethod ****** Select Link/Zone ******
    tab "Select LinkZone" prompt: "Select Link/Zone"

    //!!!radio list "SelectLink" 0.5, 1, 33.5, 15 prompt: "Select Link/Zone" resize: top
    frame "SelectLink" 0.5, 1, 33.5, 15 prompt: "Select Link/Zone" resize: top

    popdown menu "SelQry" 13, 2.5, 18, 8 List: SMP.SelList
	             variable: SMP.SelectMap.Opts.SelVal prompt: "Select Query:"  resize: top do
				 SMP.SelectMap.Save.SelVal = SMP.SelectMap.Opts.SelVal
				 RunMacro("UpdateSelect")
	enditem
    popdown menu "SelPer" same, after, 18, 5 List: SMP.Periods resize: top
	              variable: SMP.SelectMap.Opts.Period prompt: "Period:"  resize: top do
	              SMP.SelectMap.Save.Period = SMP.SelectMap.Opts.Period
				  RunMacro("UpdateSelect")
	enditem

    radio list "SelectType" 1.5, 6, 15, 4.5 variable: SMP.SelectMap.Type prompt: "Display Type"  resize: top

    radio button "Link" 2.5, 7.5 resize: top do RunMacro("UpdateSelect") enditem                //1
    radio button "Origins" same, after resize: top do RunMacro("UpdateSelect") enditem        //2
    radio button "Destinations" same, after  resize: top do RunMacro("UpdateSelect") enditem   //3

    checkbox "SelConnectors" 18, 6.5 prompt: "Connectors" variable: SMP.SelectMap.Opts.Connectors resize: top do RunMacro("UpdateSelect") enditem
    checkbox "SelLabels" same, after prompt: "Labels" variable: SMP.SelectMap.Opts.Labels resize: top do RunMacro("UpdateSelect") enditem

	frame "RoadFmtFr" same, 9.25, 15.5, 6 prompt: "Label Format"
    popdown menu "RoadFmt" 20, 10.75, 12, 10 List: SMP.fmt_list
                 variable: SMP.SelectMap.Opts.RoadFmt
                 help: "Volume Label Formats" do
        SMP.SelectMap.Save.RoadFmt = SMP.SelectMap.Opts.RoadFmt
        SelLabelOpts.FMT = SMP.fmt_strings[SMP.SelectMap.Opts.RoadFmt]
        SelLabelOpts.Units = SMP.fmt_units[SMP.SelectMap.Opts.RoadFmt]
        RunMacro("UpdateSelect")
    enditem
    checkbox "Directional" 19, 12.25 variable: SMP.SelectMap.Opts.TwoWay do
        SMP.SelectMap.Save.TwoWay = SMP.SelectMap.Opts.TwoWay
        RunMacro("UpdateSelect")
    enditem
    checkbox "Overlap" same, 13.25 variable: SMP.SelectMap.Opts.Overlap do
        SMP.SelectMap.Save.Overlap = SMP.SelectMap.Opts.Overlap
        SMP.Settings.Labels.Overlap = SMP.SelectMap.Opts.Overlap
        RunMacro("UpdateSelect")
    enditem
	checkbox "% of Tot Vol" same, 14.25 variable: SMP.SelectMap.Opts.VolShare do
        SMP.SelectMap.Save.VolShare = SMP.SelectMap.Opts.VolShare
        RunMacro("UpdateSelect")
    enditem



	//StartMethod //Select Link/Zone Map Create button
    button "SelectCreate" 1.5, 11.5, 15, 1.5 prompt: "Create" resize: top do
        HideDbox()

        //Verify that only one scenario is selected.
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Dashboard functions require that one and only one scenario is selected.")
            goto nomap
        end

        //Make sure there isn't already an ActiveSelectMap before proceeding
        current_maps = GetMapNames()
        if ActiveSelectMap != null and current_maps != null and ArrayPosition(current_maps, {ActiveSelectMap}, ) > 0 then do
            ShowMessage("Only one select link/zone map can be open at a time.  Please close the open select link/zone map before proceeding.")
            goto nomap
        end

        //Set up Args for the mapper
		select_scen = Scen.Vars.ScenFlag[1]
        select_args = Scen.Control.Simplified(Scen.Arr[select_scen][2])
        SMP.SetScenario(select_args)

		MapName = "Select Link/Zone Map"
		sel_list = SMP.SelList
		sel_val = SMP.SelectMap.Opts.SelVal
        sel_qry = sel_list[sel_val]

		//Initialize map
		SMP.MapName = MapName
        SMP.Files.Zones = select_args.TAZ
        SMP.Scope = def_scope

        Opts.[Close macro] = "CloseSelect"
		SMP.Create(SMP.[DBD File], True, Opts) //True= don't redraw map

        //Set zones to a thinner line type for select map
        SetLineWidth(SMP.Layers.Zones+"|", 1)

        //Select centroid connectors (optionally show them)
        SMP.Connectors(conn_qry, SMP.SelectMap.Opts.Connectors)

        //Join select volumes for all periods
        SMP.JoinSelectFlows(SMP.FlowList, SMP.Periods, sel_list)

        //Join the OD summary for all periods
        SMP.JoinSelectOD(SMP.SelectODList, SMP.Periods, sel_list)

        //*** Create/Refresh the FT Theme ***
        ft_theme = SMP.FTTheme()

        //*** Create Bandwidth themes for different options ***
        dim link_themes[SMP.Periods.length, sel_list.length]
        for _per = 1 to SMP.Periods.length do
            per = SMP.Periods[_per]
            for _sel = 1 to sel_list.length do
                Opts = null
                Opts.[Data Source] = "Screen"
                //Opts.ThemeName = per + " " + sel_list[_sel] + " Flow"
                //Opts.CreateOnly = True
                link_themes[_per][_sel] = SMP.Bandwidths(SMP.Views.SelectFlows+'.AB_Flow_'+sel_list[_sel]+"_"+per, Opts)
            end
        end

		//Set up link labels
        SelLabelOpts = null
        SelLabelOpts.[Priority Expression] = exp_priority
        SelLabelOpts.Font = "Arial|12"
        SelLabelOpts.CC.Font = "Arial|10"
        SelLabelOpts.ExpressionView = SMP.Views.SelectFlows
        SelLabelOpts.ClearOld = True
        SelLabelOpts.Suffix = "select"
		SelLabelOpts.FMT = SMP.fmt_strings[SMP.SelectMap.Opts.RoadFmt]
		SelLabelOpts.Units = SMP.fmt_units[SMP.SelectMap.Opts.RoadFmt]
        dim sel_exp[SMP.Periods.length, sel_list.length]
		dim sel_volshare[SMP.Periods.length, sel_list.length]
        for _per = 1 to SMP.Periods.length do
            per = SMP.Periods[_per]
            for _sel = 1 to sel_list.length do
			    //directional labels for select link volumes
                sel_f_ab = 'Format(nz(AB_Flow_'+sel_list[_sel] + "_" + per+')/%UNITS%, "%FMT%")'
				sel_f_ba = 'Format(nz(BA_Flow_'+sel_list[_sel] + "_" + per+')/%UNITS%, "%FMT%")'
				sel_f_abba = 'Format((nz(AB_Flow_'+sel_list[_sel] + "_" + per+') + nz(BA_Flow_'+sel_list[_sel] + "_" + per+'))/%UNITS%, "%FMT%")'

				//directional labels for pct of total volumes
				sel_pct_ab = 'Format(nz(AB_Flow_'+sel_list[_sel] + "_" + per+')/nz(AB_Flow_' + per+'), "*.0%")'
				sel_pct_ba = 'Format(nz(BA_Flow_'+sel_list[_sel] + "_" + per+')/nz(BA_Flow_' + per+'), "*.0%")'
				sel_pct_abba = 'Format((nz(AB_Flow_'+sel_list[_sel] + "_" + per+') + nz(BA_Flow_'+sel_list[_sel] + "_" + per+'))/(nz(AB_Flow_' + per+') + nz(BA_Flow_' + per+')), "*.0%")'

				sel_exp[_per][_sel] = '(if Dir = 1 then ' + sel_f_ab + ' else if Dir = -1 then ' + sel_f_ba + ' else ' + sel_f_abba + ')'
				sel_volshare[_per][_sel] = '(if Dir = 1 then ' + sel_pct_ab + ' else if Dir = -1 then ' + sel_pct_ba + ' else ' + sel_pct_abba + ')'
            end
        end


        //*** Create shading themes for different options ***
        dim orig_themes[SMP.Periods.length, sel_list.length]
        dim dest_themes[SMP.Periods.length, sel_list.length]

        for _per = 1 to SMP.Periods.length do
            per = SMP.Periods[_per]
            for _sel = 1 to sel_list.length do
                Opts = null
                Opts.[Data Source] = "Screen"
                Opts.ThemeName = per + " " + sel_list[_sel] + " Origins ("+per+")"
                Opts.CreateOnly = True
                orig_themes[_per][_sel] = SMP.Shading(SMP.Views.SelectOD+"."+sel_list[_sel]+"_Origins_"+per, "Optimal", 8, Opts)

                Opts.ThemeName = per + " " + sel_list[_sel] + " Destinations ("+per+")"
                Opts.ThemeName = per + " " + sel_list[_sel] + " Destinations ("+per+")"
                dest_themes[_per][_sel] = SMP.Shading(SMP.Views.SelectOD+"."+sel_list[_sel]+"_Destinations_"+per, "Optimal", 8, Opts)
            end
		end

		//Find select matrix by period
		dim select_mat[SMP.Periods.length]
		for _per = 1 to SMP.Periods.length do
            period = SMP.Periods[_per]
		    select_mat[_per] = Substitute(select_args.SelectMatrix, "%PER_HWY%", period, )
		end

		//Make read only
		CurrentViews = GetViews()
		CurrentViews = CurrentViews[1]
		//if !TrafficMap.Opts.[Input Network] then do
		if True then do //!!! Currently always assume not input network
			for _lyr = 1 to SMP.Layers.length do
				lyr = SMP.Layers[_lyr][2]
				if ArrayPosition(CurrentViews, {lyr}, ) > 0 then
					SetViewReadOnly(lyr, "True")
			end
			for _vw = 1 to SMP.Views.length do
				vw = SMP.Views[_vw][2]
				if ArrayPosition(CurrentViews, {vw}, ) > 0 then
					SetViewReadOnly(vw, "True")
			end

		end

        SetMapRedraw(SMP.Map, "True")
        RunMacro("SetSelectType")

        ActiveSelectMap = SMP.Map
        DisableItem("SelectCreate")

        //If Canceled, we will skip to here
        nomap:


        ShowDbox()

    enditem	//EndMethod

	//StartMethod //Select Link/Zone Map Create button
    button "ODPairs" 1.5, 13.75, 15, 1.5 prompt: "OD Pairs" resize: top do
        HideDbox()

        //Verify that only one scenario is selected.
        if Scen.Vars.ScenFlag.length != 1 then do
            ShowMessage("Dashboard functions require that one and only one scenario is selected.")
            goto nomap
        end

        //Set up Args for the mapper
		select_scen = Scen.Vars.ScenFlag[1]
        select_args = Scen.Control.Simplified(Scen.Arr[select_scen][2])
        SMP.SetScenario(select_args)

		sel_list = SMP.SelList
		sel_val = SMP.SelectMap.Opts.SelVal

		//Find select matrix by period
		dim select_mat[SMP.Periods.length]
		for _per = 1 to SMP.Periods.length do
            period = SMP.Periods[_per]
		    select_mat[_per] = Substitute(select_args.SelectMatrix, "%PER_HWY%", period, )
		end

        //Open the select matrix into a dataview, with the ZoneID index
        sel_tmp_file = select_mat[SMP.SelectMap.Opts.Period]
        sel_tmp_vw = OpenTable("SelectTrips", "MATRIX", {sel_tmp_file, "ZoneID", "ZoneID"})

        //Rename fields and open into an editor window, sorted by number of trips
        fields = GetFields(sel_tmp_vw, )
		RenameField(sel_tmp_vw +"."+fields[1][1], "Origin")
		RenameField(sel_tmp_vw +"."+fields[1][2], "Destination")

		CreateEditor(SMP.Periods[SMP.SelectMap.Opts.Period] + " OD Pairs for " + sel_list[sel_val] + " Trips", sel_tmp_vw+"|", {"Origin", "Destination", sel_list[sel_val]}, {{"Read Only", "True"}}) // show table
		SetRowOrder(SMP.Periods[SMP.SelectMap.Opts.Period] + " OD Pairs for " + sel_list[sel_val] + " Trips", {{sel_list[sel_val], "Descending"}}) // sort table in descending order by select trips
		sel_mat = null

		//If Canceled, we will skip to here
        nomap:

        ShowDbox()

    enditem	//EndMethod

	Macro "UpdateSelect" do
        //If we already have a select link map, update it
        if ActiveSelectMap != null then do

            on NotFound do
                on NotFound default
				ActiveSelectMap = null
                EnableItem("SelectCreate")
                RunMacro("Update")
                goto NoSelectMapAvailable
            end
            map = SetMap(ActiveSelectMap)
            on NotFound default

            RunMacro("SetSelectType")

            NoSelectMapAvailable:
        end
    enditem //EndMethod

	Macro "SetSelectType" do

        orig_lyr = GetLayer()
        sel_val = SMP.SelectMap.Opts.SelVal

        // *** Hide all themes in the map ***
        //MP = SelectMap.MP
        SMP.ClearThemes(SMP.Layers.Links)
        SMP.ClearThemes(SMP.Layers.Zones)

        // *** Theme and label settings for link map ***
        if SMP.SelectMap.Type = 1 then do
            SetLayer(SMP.Layers.Links)
            ShowTheme(, link_themes[SMP.SelectMap.Opts.Period][sel_val])
			if SMP.SelectMap.Opts.VolShare = 0 then do // display select volumes
                if SMP.SelectMap.Opts.Labels and SMP.SelectMap.Opts.TwoWay = 0 then do
                    SMP.Label(sel_exp[SMP.SelectMap.Opts.Period][sel_val], SelLabelOpts)
                end
			    if SMP.SelectMap.Opts.Labels and SMP.SelectMap.Opts.TwoWay = 1 then do
                    exp_selTW = {'Format(AB_Flow_'+sel_list[sel_val]+"_"+SMP.Periods[SMP.SelectMap.Opts.Period]+ '/%UNITS%, "%FMT%")',
			    	             'Format(BA_Flow_'+sel_list[sel_val]+"_"+SMP.Periods[SMP.SelectMap.Opts.Period]+ '/%UNITS%, "%FMT%")'}
                    SMP.SelectLabelTwoWay(exp_selTW, SelLabelOpts)
                end
			    if !SMP.SelectMap.Opts.Labels then do
                    SMP.HideLabels()
                end
			end else do // display total link volumes with share of critical volume in parentheses
			    if SMP.SelectMap.Opts.Labels and SMP.SelectMap.Opts.TwoWay = 0 then do
                    SMP.Label(sel_volshare[SMP.SelectMap.Opts.Period][sel_val], SelLabelOpts)
                end
			    if SMP.SelectMap.Opts.Labels and SMP.SelectMap.Opts.TwoWay = 1 then do
                    exp_selTW = {'Format(AB_Flow_'+sel_list[sel_val]+"_"+SMP.Periods[SMP.SelectMap.Opts.Period]+ '/ AB_Flow_'+SMP.Periods[SMP.SelectMap.Opts.Period] + ' , "*.0%")',
			    	             'Format(BA_Flow_'+sel_list[sel_val]+"_"+SMP.Periods[SMP.SelectMap.Opts.Period]+ '/ BA_Flow_'+SMP.Periods[SMP.SelectMap.Opts.Period] + ' , "*.0%")'}
                    SMP.SelectLabelTwoWay(exp_selTW, SelLabelOpts)
                end
			    if !SMP.SelectMap.Opts.Labels then do
                    SMP.HideLabels()
                end
			end
        end
        else do
            SetLayer(SMP.Layers.Links)
            ShowTheme(, ft_theme)
        end

        //*** Theme and label settings for TAZ O or D map ***
        if SMP.SelectMap.Type = 2 or SMP.SelectMap.Type = 3 then do

            SetLayer(SMP.Layers.Zones)
            if SMP.SelectMap.Type = 2 then ShowTheme(, orig_themes[SMP.SelectMap.Opts.Period][sel_val])
            if SMP.SelectMap.Type = 3 then ShowTheme(, dest_themes[SMP.SelectMap.Opts.Period][sel_val])
            SetLayer(SMP.Layers.Links)
            SMP.HideLabels()
        end

        //*** Centroid connector and local street display ***
        if SMP.SelectMap.Opts.Connectors then do
            SetDisplayStatus(SMP.Layers.Links+"|CentroidConnectors", "Active")
        end else do
            SetDisplayStatus(SMP.Layers.Links+"|CentroidConnectors", "Invisible")
        end

        //!!! no local streets !!! if SelectMap.Opts.Locals then do
        //    SetDisplayStatus(SMP.Layers.Links+"|Local Streets", "Active")
        //end else do
        //    SetDisplayStatus(SMP.Layers.Links+"|Local Streets", "Invisible")
        //end

        SetLayer(orig_lyr)

        SMP.Redraw()

    enditem //EndMethod

	//EndMethod - Select Link/Zone Tab


    Macro "closing" do
        Return()
    enditem //EndMethod


EndDbox


//====== Initialization ======//       (Create Network)
Macro "SEMCOG Update Directory" (Args)
//Re-link the route system to the highway line layer

    // Inputs
    db_file = Args.[Highway DB]
    rs_file = Args.[Route System]

    // update route system line db
    {, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
    ok = (link_lyr <> null) if !ok then goto exit
    ModifyRouteSystem(rs_file, {{"Geography", db_file, link_lyr}})

    exit:
    return(ok)
EndMacro

Macro "Export Network Data" (Args)

    // Input Files
    db_file = Args.[Highway DB]
	allstrt_file = Args.[AllStreets DB]
    rs_file = Args.[Route System]
	taz_file = Args.[TAZ]
	maz_file = Args.[MAZ]
    mode_tb = Args.[Mode Table]
	output = Args.[Working Files]
    // output = Args.[Summary Report]
    path = Splitpath(output)
    output_ = path[1] + path[2]
    // CreateDirectory(output_)
	   
	//Export highway network
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
    ok = (node_lyr <> null & link_lyr <> null)
    if !ok then goto exit
    
    // Create From and To ID node fields on link layer
    CreateNodeField(link_lyr, "A_Node", node_lyr + ".ID", "From", )
    CreateNodeField(link_lyr, "B_Node", node_lyr + ".ID", "To", )
    
    link_fields = GetFields(link_lyr, "All")
    node_fields = GetFields(node_lyr, "All")
    //"C:/RSG_test/semcog/Exported_networks/nodes_net.shp"
    ExportArcViewShape(link_lyr, output_ + "\\links_net.shp", {{"Fields": link_fields[1]},{"Projection", "nad83:2113", {"units=us-ft"}}})
    ExportArcViewShape(node_lyr, output_ + "\\nodes_net.shp", {{"Fields": node_fields[1]}, {"Projection", "nad83:2113", {"units=us-ft"}}})
    ExportView(link_lyr + "|", 'dBASE', output_ + "\\links_net.dbf", {'A_Node', 'B_Node', 'NFC', 'LENGTH'}, )
    ExportView(node_lyr + "|", 'dBASE', output_ + "\\nodes_net.dbf", , )
    
    proj = {"nad83:2113", {"units=us-ft"}}
    // define ellipse depending on where you are in the world
    def_ellps = "GRS80" // North America
    //def_ellps = "WGS84" // Remainder of World
 
    RunMacro("WKT Create PRJ", output_ + "\\links_net.shp", proj, def_ellps)
    RunMacro("WKT Create PRJ", output_ + "\\nodes_net.shp", proj, def_ellps)

    
    //Export stops and routes to csv from the route system file
    {rt_lyr, stop_lyr, ph_lyr} = RunMacro("TCB Add RS Layers", rs_file, "ALL", )
    //'C:/RSG_test/semcog/Exported_networks/route_stops.csv'
    ExportView(stop_lyr + "|", 'CSV', output_ + "\\route_stops.csv", , {{"CSV Header", "True"}})
    ExportView(rt_lyr + "|", 'CSV', output_ + "\\route_lines.csv", , {{"CSV Header", "True"}})

    mode_vw = RunMacro("TCB OpenTable",,, {mode_tb})
    ExportView(mode_vw + "|", 'CSV', output_ + "\\transit_operator_list.csv", , {{"CSV Header", "True"}})
	
	//Export AllStreet 
	{node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", allstrt_file)
    ok = (node_lyr <> null & link_lyr <> null)
    if !ok then goto exit
    
    // Create From and To ID node fields on link layer
    CreateNodeField(link_lyr, "A_Node", node_lyr + ".ID", "From", )
    CreateNodeField(link_lyr, "B_Node", node_lyr + ".ID", "To", )
    
    link_fields = GetFields(link_lyr, "All")
    node_fields = GetFields(node_lyr, "All")
    
    ExportArcViewShape(link_lyr, output_ + "\\links_all.shp", {{"Fields": link_fields[1]},{"Projection", "nad83:2113", {"units=us-ft"}}})
    ExportArcViewShape(node_lyr, output_ + "\\nodes_all.shp", {{"Fields": node_fields[1]}, {"Projection", "nad83:2113", {"units=us-ft"}}})
    ExportView(link_lyr + "|", 'dBASE', output_ + "\\links_all.dbf", {'A_Node', 'B_Node', 'NFC', 'LENGTH'}, )
    ExportView(node_lyr + "|", 'dBASE', output_ + "\\nodes_all.dbf", , )
    
    proj = {"nad83:2113", {"units=us-ft"}}
    // define ellipse depending on where you are in the world
    def_ellps = "GRS80" // North America
    //def_ellps = "WGS84" // Remainder of World
 
    RunMacro("WKT Create PRJ", output_ + "\\links_all.shp", proj, def_ellps)
    RunMacro("WKT Create PRJ", output_ + "\\nodes_all.shp", proj, def_ellps)

	
	// Export TAZ
    {taz_lyr} = RunMacro("TCB Add DB Layers", taz_file)
    taz_fields = GetFields(taz_lyr, "All")
    ExportArcViewShape(taz_lyr, output_ + "SEMCOG_TAZ.shp", {{"Fields": taz_fields[1]},{"Projection", "nad83:2113", {"units=us-ft"}}})
	ExportView(taz_lyr + "|", 'dBASE', output_ + "\\SEMCOG_TAZ.dbf", , )
	proj = {"nad83:2113", {"units=us-ft"}}
	def_ellps = "GRS80" // North America
	RunMacro("WKT Create PRJ", output_ + "\\SEMCOG_TAZ.shp", proj, def_ellps)
	
	//Export MAZ
    {maz_lyr} = RunMacro("TCB Add DB Layers", maz_file)
    maz_fields = GetFields(maz_lyr, "All")
    ExportArcViewShape(maz_lyr, output_ + "\\SEMCOG_MAZ.shp", {{"Fields": maz_fields[1]}, {"Projection", "nad83:2113", {"units=us-ft"}}})
	ExportView(maz_lyr + "|", 'dBASE', output_ + "\\SEMCOG_MAZ.dbf", , )
	proj = {"nad83:2113", {"units=us-ft"}}
	def_ellps = "GRS80" // North America
	RunMacro("WKT Create PRJ", output_ + "\\SEMCOG_MAZ.shp", proj, def_ellps)
    
    exit:
    return(ok)
EndMacro

Macro "SEMCOG Highway Process" (Args)
    //Fill in highway-related fields
    // - Run only on the first feedback loop
    // - Relevant fields are updated by the feedback macro

    shared UT

NextStep= "Define Files and Data"
SetStatus(1, NextStep, )

	// Input Files
	db_file = Args.[Highway DB]
	spd_cap_tb = Args.[Speed Capacity Table]
    taz_file = Args.[TAZ]
    zdata_file = Args.[TAZ Land Use Data]

    // Parameters
	walk_speed = Args.[Walk Speed]
	vod = Args.[Distance weight]        // value of distance (dollars per mile)
	vot = Args.[Time weight]            // value of time (dollars per minute)
    hwy_pers = Args.HwyPeriods

	Directions = {"AB", "BA"}
	Periods6 = {"EA", "AM", "MD", "PM", "EV", "DY"}
	Periods = {"EA", "AM", "MD", "PM", "EV"}
	period_n = Periods.length
    tran_lkup_sets = 3   // number of transit link time look up sets

//EndStep
NextStep= "Add Fields to Network"
SetStatus(1, NextStep, )

	{node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
	spd_cap_vw = RunMacro("TCB OpenTable",,, {spd_cap_tb})
	ok = (link_lyr <> null && spd_cap_vw <> null)
	if !ok then goto exit

    {Flds,} = GetFields(link_lyr, "All")
    NewFlds = null

	NewFlds = {{"Walktime",           "Real"},
              {"Alpha",        "Real"},
              {"Beta",        "Real"}}

    for i = 1 to 2  do  NewFlds = NewFlds + {{Directions[i] + "_TIME", "Real" }}   end
    for i = 1 to 2  do  NewFlds = NewFlds + {{Directions[i] + "_DrvTime", "Real"}}    end
    for i = 1 to 2  do  NewFlds = NewFlds + {{Directions[i] + "_FFS", "Real" }}   end
    for i = 1 to 2  do  NewFlds = NewFlds + {{Directions[i] + "_DYCap", "Integer"}} end

    for i = 1 to period_n do
        for j = 1 to 2 do
            NewFlds = NewFlds + {{Directions[j] + "_" + Periods[i] + "Cap",  "Integer"}}
        end
    end

    for i = 1 to period_n do
	   for k = 1 to tran_lkup_sets do
      	    for j = 1 to 2 do
                NewFlds = NewFlds + {{Directions[j] + "_" + Periods[i] + "_IVTT_"+i2s(k), "Real"}}
             end
       end
	end

    for i = 1 to period_n do
        for j = 1 to 2 do
            NewFlds = NewFlds + {{Directions[j] + "_" + Periods[i] + "_HwyT", "Real"}}
        end
    end

    for i = 1 to period_n do
        for j = 1 to 2 do
            NewFlds = NewFlds + {{Directions[j] + "_" + Periods[i] + "_HwyC", "Real"}}
        end
    end

    for i = 1 to period_n do
        for j = 1 to 2 do
            NewFlds = NewFlds + {{Directions[j] + "_" + Periods[i] + "_HwyS", "Real"}}
        end
    end

    //Check for saved feedback fields, add if not present
    dirs = {"AB", "BA"}
    for d in dirs do
       for p in hwy_pers do
           NewFlds = NewFlds + {{d+"_"+p+"FB", "Real"}} //e.g., AB_AMFB
       end
    end

    UT.AddViewFields(NewFlds, link_lyr, null)

//EndStep
NextStep= "Compute Link Area Types"
SetStatus(1, NextStep, )

    //Put the TAZ in a temporary layer, since the AreaType field must be part
    //  of the TAZ layer for the CalcLinkAT utility to work
    taz2_file = GetTempFileName(".dbd")
    CopyDatabase(taz_file, taz2_file)

    //Create a map with the TAZ and network layers
    {scp,,}  = GetDBInfo(db_file)
    Opts = null

    map = CreateMap("AT_Tag", {"Scope":scp})
    map_link_lyr = AddLayer(map, link_lyr, db_file, link_lyr, )
    RunMacro("G30 new layer default settings", map_link_lyr)

    {taz_lyr} = GetDBLayers(taz2_file)
    taz_lyr = AddLayer(map, taz_lyr, taz2_file, taz_lyr, )
    RunMacro("G30 new layer default settings", taz_lyr)

    //Add the AREA_TYPE field to the temp zone layer and fill with AreaType from zdata file
    ok = RunMacro("TCB Add View Fields", {taz_lyr, {{"AREA_TYPE", "Integer"}}})
    if !ok then goto exit

    t = SplitPath(zdata_file)
    zdata_vw = OpenTable(t[3], "CSV", {zdata_file})

    taz_join = JoinViews("TAZ+ZDATA", taz_lyr+".ID", zdata_vw+".ZONE", )

    AT = GetDataVector(taz_join+"|", zdata_vw+".AreaType", )
    SetDataVector(taz_join+"|", taz_lyr+".AREA_TYPE", AT, )

    CloseView(taz_join)
    CloseView(zdata_vw)

    //Run the AT utility
    Opts = null
    Opts.LinkField = "AREA_TYPE"
    Opts.ZoneField = "AREA_TYPE"
    Opts.Buffer = 0.05
    Opts.Override = {{"Select * Where NFC BETWEEN 81 and 98", 0}} //Set external connectors to AT=0
    Opts.Default = 5
    UT.CalcLinkAT(link_lyr, taz_lyr, Opts)

    //Process ramp AT
    ramp_qry = 'Select * Where NFC_FLAG = "RON" or NFC_FLAG = "ROF" or NFC_FLAG = "RFF" or NFC_FLAG = "RFS" or NFC_FLAG = "RSF"'
    Opts = null
    Opts.[AT Field] = "AREA_TYPE"
    UT.CalcRampAT(link_lyr, node_lyr, ramp_qry, Opts)

    //Drop the TAZ layer and delete the temporary copy
    CloseMap(map)
    DeleteDatabase(taz2_file)

//EndStep
NextStep= "Load Highway Link Variables"
SetStatus(1, NextStep, )

    //CloseMap may close the link layer, so re-open if not present
    if ArrayPosition(GetViews(), {link_lyr}, ) = 0 then do
        link_lyr = null
        node_lyr = null
        {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
        ok = (link_lyr != null)
        if !ok then goto exit
    end

    // join lookup table to link layer
    CreateExpression(link_lyr, "key1", 'String(AREA_TYPE) + " " + String(NFC) + " " + NFC_Flag',	//Updated the function class by JChen in August 2015
                     {{"Type", "String"}})
    CreateExpression(spd_cap_vw, "key2", 'String(AT) + " " + String(NFC_N) + " " + SFlag',
                     {{"Type", "String"}})
    jvw = JoinViews("jvw", link_lyr+".key1", spd_cap_vw+".key2",)
    vw_set = jvw + "|"

    //Read link and lookup vectors
    Flds = {"Dir", "NFC", "ModE_ID", "Length", "Cent_Lane", "FFS", "CAPA", "ALPHA_V", "BETA_V",
            "AB_AMFB", "BA_AMFB", "AB_MDFB", "BA_MDFB", "AB_PMFB", "BA_PMFB"}
    {dir_v, fc, mode, dist, cl, ff_spd, capa1, alpha, beta,
     ab_am_fb, ba_am_fb, ab_md_fb, ba_md_fb, ab_pm_fb, ba_pm_fb} = GetDataVectors(vw_set, Flds, )

     //Saved Feedback Fields.  Only present for AM and MD and PM
     fb_flds = {{ab_am_fb, ab_md_fb, ab_pm_fb, ,},
                {ba_am_fb, ba_md_fb, ba_pm_fb, ,}}

    //Hourly Adjustment factors from lookup table
    dim Flds[6]
    for ii = 1 to 6 do
        Flds[ii] = Periods6[ii]+"_HrAdj"
    end
    HrAdj = GetDataVectors(vw_set, Flds, )

    //Lanes by direction
    LanesDir = GetDataVectors(vw_set, {"AB_LANES", "BA_LANES"}, )

//EndStep
NextStep= "Set Highway Link Variables"
SetStatus(1, NextStep, )

    // ===== Non-Directional =====
    dist = Max(0.0001, dist) //Prevent issues with very short links

    ff_time = dist / ff_spd * 60
    walk_time = if (mode = 2 | mode = 3) then
        max(0.0001, dist / walk_speed * 60)
        else null

    SetVs = null
    SetVs.walktime = walk_time
    SetVs.ALPHA = alpha
    SetVs.BETA = beta

    // ===== Directional =====
    for ii = 1 to 2 do

        dir = Directions[ii] + "_"
        lanes = LanesDir[ii]

        //Vector indicating if direction ok
        valid = (ii = 1 & dir_v >= 0 | ii = 2 & dir_v <= 0) & (fc >= 90 | lanes > 0)

        //Freeflow speeds and times
        SetVs.(dir+"FFS") = if valid then ff_spd else null
        SetVs.(dir+"TIME") = if valid then ff_time else null //!!! rename to FFTIME for clarity ???
        SetVs.(dir+"DrvTime") = if (valid & (mode = 1 | mode = 2 | (mode >= 4 & mode < 10))) then ff_time else null

        //Hourly Link Capacity (not saved to network)
        capa = if (valid & fc >= 90) then capa1
                else if (valid & lanes > 0) then
                    capa1 * lanes + capa1 * Nz(cl) * 0.1 //increase 10% with CTL
                else null

        //Factor Link Capacity by time period
        for jj = 1 to HrAdj.length do
            SetVs.(dir+Periods6[jj]+"Cap") = capa * HrAdj[jj]
        end

        //Congested times (Set to freeflow time if FB override is not present.)
        for jj = 1 to Periods.length do

            fb_speed = fb_flds[ii][jj]
            fb_time = dist * 60 / fb_speed
            time = if valid then (if fb_time > 0 then fb_time else ff_time) else null
            cost = vod * dist + vot * time

            SetVs.(dir+Periods[jj]+"_HwyT") = time
            SetVs.(dir+Periods[jj]+"_HwyC") = cost
            SetVs.(dir+Periods[jj]+"_HwyS") = if valid then (if fb_speed > 0 then fb_speed else ff_spd) else null
        end

    end //direction

    //Write to view, then close lookup
    SetDataVectors(vw_set, SetVs, )

//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )

    //Close files
    CloseView(jvw)
    CloseView(spd_cap_vw)
	DropLayerFromWorkspace(link_lyr)
	DropLayerFromWorkspace(node_lyr)

    RunMacro("G30 File Close All")

exit:
    Return(ok)
//EndStep
EndMacro


Macro "SEMCOG Transit Process" (Args)
    //Fill in transit time fields
    // Run for all feedback loops so transit speeds can be updated based on highway speeds

NextStep= "Define Files and Data"
SetStatus(1, NextStep, )

	// Input Files
	db_file = Args.[Highway DB]
	spd_cap_tb = Args.[Speed Capacity Table]

    // Parameters
	walk_speed = Args.[Walk Speed]
	vod = Args.[Distance weight]        // value of distance (dollars per mile)
	vot = Args.[Time weight]            // value of distance (dollars per minute)

	Directions = {"AB", "BA"}
    Periods = {"EA", "AM", "MD", "PM", "EV"}

    //IVTT for these periods will be filled with matching Periods2 times.
    // On final assignment, PM and NT transit times will be updated with final
    //  highway assignment results
    //PeriodsMatch = {"PM", "EV", "EA"}

//EndStep
NextStep= "Update Transit IVTT Values"
SetStatus(1, NextStep, )

	{node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
	spd_cap_vw = RunMacro("TCB OpenTable",,, {spd_cap_tb})
	ok = (link_lyr <> null && spd_cap_vw <> null)
	if !ok then goto exit

    //Read congested times
    Flds = null
    for ii = 1 to Directions.length do
        dir = Directions[ii]+"_"
        for jj = 1 to Periods.length do
            per = Periods[jj]
            Flds = Flds + {dir+per+"_HwyT"}
        end
    end
    Flds = Flds + {"AB_TIME", "BA_TIME", "TransitOnly"}
    Vs = GetDataVectors(link_lyr+"|", Flds, {{"Return Options Array", "True"}})

    //Set congested times into IVTT
    SetVs = null
    for ii = 1 to Directions.length do
        dir = Directions[ii]+"_"
        for jj = 1 to Periods.length do
            per = Periods[jj]
            //per2 = PeriodsMatch[jj]

            cong_time = Vs.(dir+per+"_HwyT") //Load appropriate congested speed
            ff = Vs.(dir+"TIME")


            //Set IVTT_1 to congested time for period and reverse period
            SetVs.(dir+per+"_IVTT_1") = cong_time
            //SetVs.(dir+per2+"_IVTT_1") = cong_time

            //Set IVTT_2 to Freeflow Time
            //(No change between feedback loops)
            SetVs.(dir+per+"_IVTT_2") = ff
            //SetVs.(dir+per2+"_IVTT_2") = ff

            //Set IVTT_3 based on TransitOnly (freeflow on transit only links)
            SetVs.(dir+per+"_IVTT_3") = if Vs.TransitOnly = 1 then ff else cong_time
            //SetVs.(dir+per2+"_IVTT_3") = if Vs.TransitOnly = 1 then ff else cong_time

        end //jj (periods)
    end //ii (dir)


    SetDataVectors(link_lyr+"|", SetVs, )



//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )

    //Close files
	DropLayerFromWorkspace(link_lyr)
	DropLayerFromWorkspace(node_lyr)

    RunMacro("G30 File Close All")

exit:
    Return(ok)
//EndStep
EndMacro


Macro "SEMCOG Zonal Walk Percentages" (Args)
    shared UT
NextStep= "Define files and fields"
SetStatus(1, NextStep, )

    //Input/intermediate files
    dbd_file = Args.[Highway DB]
    rts_file = Args.[Route System]
    taz_file = Args.[TAZ]
	zonal_walk = Args.[Zonal Walk]

    //Deinfe params
    pkop_pers  = Args.PkOpPeriods   //PK/OP
    distance = {"Quarter", "Half"}
    distancevalue = {0.25, 0.5}

    //Define output files
    // (using tnw folder for temporary files, to be deleted once step is complete)
    tnw_files = Args.[Transit Network]
    t = SplitPath(tnw_files)
    tnw_path = t[1]+t[2]

    {taz_lyr} = RunMacro("TCB Add DB Layers", taz_file)
	ZID = GetDataVector(taz_lyr+"|", "ID", {{"Sort Order", {{"ID", "Ascending"}}}})
	zone_num = ZID.length


//EndStep
NextStep= "Add fields to TAZ layer"
SetStatus(1, NextStep, )


// Add Fields to Zone Table
  //{Flds,} = GetFields(taz_lyr, "All")
	//if !ArrayPosition(Flds, {"Walk_Buf_AM_Qrtr"},) then do      // if fields do not exist yet
	// NewFlds.Zone_ID = "integer"
	// NewFlds.Walk_Buf_AM_Qrtr= "real"
    // NewFlds.Walk_Buf_MD_Qrtr= "real"
    // NewFlds.Walk_Buf_AM_Half= "real"
    // NewFlds.Walk_Buf_MD_Half= "real"
    // NewFlds.[Walk_Access Flag]= "integer"
    // NewFlds.[Walk_Qrtr_AM]= "real"
    // NewFlds.[Walk_Qrtr_MD]= "real"
    // NewFlds.[Walk_Half_AM]= "real"
    // NewFlds.[Walk_Half_MD]= "real"
        //ok = RunMacro("TCB Add View Fields", {taz_lyr, NewFlds})
        //if !ok then goto quit
	 //end

	NewFlds = {{"Zone_ID", "Integer", 10, 0},
	           {"Walk_Buf_AM_Qrtr", "Real", 10, 3},
			   {"Walk_Buf_MD_Qrtr", "Real", 10, 3},
			   {"Walk_Buf_AM_Half", "Real", 10, 3},
			   {"Walk_Buf_MD_Half", "Real", 10, 3},
			   {"Walk_Access Flag", "Integer", 10, 0},
			   {"Walk_Qrtr_AM", "Real", 10, 2},
			   {"Walk_Qrtr_MD", "Real", 10, 2},
			   {"Walk_Half_AM", "Real", 10, 2},
			   {"Walk_Half_MD", "Real", 10, 2}}


	//Open zonal walk view
	zwalk_vw = CreateTable("Zonal Walk Percentages", zonal_walk, "FFB", NewFlds)
	rh = AddRecords(zwalk_vw, null, null, {{"Empty Records", zone_num}}) // add empty records totaling the number of zones (2899)
	SetView(zwalk_vw)
	SetDataVector(zwalk_vw+"|", "Zone_ID", ZID, ) // set zone_id to id from taz layer

//EndStep
NextStep= "Create Buffers"
SetStatus(1, NextStep, )

    //Open highway dbd in a map
    info = GetDBInfo(dbd_file)
    map = CreateMap("Map", {{"Scope", info[1]},{"Auto Project", "True"},{"Position", 100, 150}})
    lyrs = AddRouteSystemLayer(map, "Bus Routes", rts_file, )
    {route_lyr, stop_lyr, pstop_lyr, node_lyr, link_lyr} = lyrs //Ok if pstops null when  no physical stops.  not used by this macro.
    RunMacro("Set Default RS Style", lyrs, "True", "True")

    //Add Zone Layer
    zone_lyr = AddLayer(map, taz_lyr, taz_file, taz_lyr, )
    RunMacro("G30 new layer default settings", zone_lyr)

    //Export selected routes to line files
    SetLayer(route_lyr)
    peak = SelectByQuery("Peak", "Several", "Select * where AM_HDWY<999 or PM_HDWY<999",)
    offpeak = SelectByQuery("OffPeak", "Several", "Select * where MD_HDWY<999 or EV_HDWY<999 or EA_HDWY<999",)

    pkline_lyr = "PeakTransitLines"
    opline_lyr = "OffpeakTransitLines"
    pkline_file = tnw_path+pkline_lyr+".cdf"
    opline_file = tnw_path+opline_lyr+".cdf"

    ExportGeography(route_lyr+"|Peak", pkline_file, {{"Layer Name",pkline_lyr}})
    ExportGeography(route_lyr+"|OffPeak", opline_file,{{"Layer Name",opline_lyr}})

    //Add exported lines to the map
    pkline_lyr = AddCDFLayer (map, pkline_lyr, pkline_file, pkline_lyr)
    RunMacro("G30 new layer default settings", pkline_lyr)
    opline_lyr = AddCDFLayer (map, opline_lyr, opline_file, opline_lyr)
    RunMacro("G30 new layer default settings", opline_lyr)

    //Create Buffers around Peak and OffPeak Layers
    line_lyrs = {pkline_lyr, opline_lyr}

    //Add the buffer layers to the map
    dim buffer_lyrs[pkop_pers.length, distance.length]  //[_per][_dist]
    dim buffer_files[pkop_pers.length, distance.length] //temporary filenames, to be deleted at end of macro
    BufferOpts = {"Exterior": "Merged", "Interior": "Merged"}
    for _per = 1 to pkop_pers.length do
        for _dist = 1 to distance.length do

            pkop = pkop_pers[_per]
            dist = distance[_dist]
            distval = distancevalue[_dist]

            SetLayer(line_lyrs[_per])
            buffer_files[_per][_dist] = tnw_path+pkop+dist+"Buffers.dbd"
            buffer_lyrs[_per][_dist] = pkop+dist+"Buffers"
            CreateBuffers(buffer_files[_per][_dist], buffer_lyrs[_per][_dist], {}, "Value", {distval}, BufferOpts)
            name = line_lyrs[_per]+dist
            buffer_lyrs[_per][_dist] = AddLayer(map, buffer_lyrs[_per][_dist], buffer_files[_per][_dist], buffer_lyrs[_per][_dist], )
            RunMacro("G30 new layer default settings", buffer_lyrs[_per][_dist])
    	end
    end

    // Create buffers around stops
    SetLayer(stop_lyr)
    sbuffer_file = tnw_path+"RouteStopBuffer.dbd"
    sbuffer_lyr = "RouteStopBuffer"
    CreateBuffers(sbuffer_file, sbuffer_lyr, {}, "Value", {0.5}, BufferOpts)
    sbuffer_lyr = AddLayer(map, sbuffer_lyr, sbuffer_file, sbuffer_lyr, )
    RunMacro("G30 new layer default settings", sbuffer_lyr)

//EndStep
NextStep= "Walk Access Flag"
SetStatus(1, NextStep, )

    //Fill all with zero
    //zone_count = GetRecordCount(taz_lyr, )
	join_vw = JoinViews("TAZ + Zonal Walk", taz_lyr+".ID", zwalk_vw+".Zone_ID", )
    SetDataVector(join_vw+"|", zwalk_vw+".Walk_Access Flag", Vector(zone_num, "Long", {"Constant":0}), )

    //Fill within 1/2 mile of transit stop with 1
	SetLayer(taz_lyr)
	set_count = SelectByVicinity("WACC", "Several", sbuffer_lyr+"|", 0.0, {"Inclusion":"Intersecting"})
    SetDataVector(join_vw+"|WACC", zwalk_vw+".Walk_Access Flag", Vector(set_count, "Long", {"Constant":1}), )

//EndStep
NextStep= "Walk Access Shares"
SetStatus(1, NextStep, )

    //Determine amount of zone that overlaps

    pkop2_pers = {"AM", "MD"}
    distance2 = {"Qrtr", "Half"}
    for _per = 1 to pkop_pers.length do
        for _dist = 1 to distance.length do

            pkop2 = pkop2_pers[_per]
            dist2 = distance2[_dist]

            buff_lyr = buffer_lyrs[_per][_dist]
            buff_fld = "Walk_Buf_"+pkop2+"_"+dist2


            SetLayer(taz_lyr)
            ComputeIntersectionPercentages({taz_lyr+"|WACC", buff_lyr+"|"}, tnw_path+"IntersectTemp.bin", )
            over_tb = OpenTable("Overlay", "FFB", {tnw_path+"IntersectTemp.bin"})
            SetView(over_tb)
            SelectByQuery("Buffer", "Several", "Select * Where Percent_2 > 0", )
            AggOpts = {{"Percent_1", "Sum"}}
            agg_vw = AggregateTable("AggBuffer", over_tb+"|Buffer", "MEM", "AggBuffer", "Area_1", AggOpts,  )
            join_agg = JoinViews("JoinAgg", join_vw+".ID", agg_vw+".Area_1", )
            V = GetDataVectors(join_agg+"|", {"Percent_1", "Area"}, )
            SetDataVector(join_agg+"|", zwalk_vw +"." + buff_fld, nz(V[1]*V[2]), ) //!!! Area maintained for backwards compatibility, but divided back out later.
            CloseView(join_agg)
            CloseView(agg_vw)
            CloseView(over_tb)
            DeleteTableFiles("FFB", tnw_path+"IntersectTemp.bin", )


        end //_dist
    end //per


    /*
    // EXTREMELY SLOW.  Version above is orders of magnitude faster
    ColumnAggregate(taz_lyr+"|WACC", 0, buffer_lyrs[1][1]+"|", {{"Walk_Buf_AM_Qrtr", "Sum", "Area", }}, )
    ColumnAggregate(taz_lyr+"|WACC", 0, buffer_lyrs[1][2]+"|", {{"Walk_Buf_AM_Half", "Sum", "Area", }}, )
    ColumnAggregate(taz_lyr+"|WACC", 0, buffer_lyrs[2][1]+"|", {{"Walk_Buf_MD_Qrtr", "Sum", "Area", }}, )
    ColumnAggregate(taz_lyr+"|WACC", 0, buffer_lyrs[2][2]+"|", {{"Walk_Buf_MD_Half", "Sum", "Area", }}, )
    */

    //Compute walk percentages
    Flds = {"Area", "Walk_Buf_AM_Qrtr", "Walk_Buf_AM_Half", "Walk_Buf_MD_Qrtr", "Walk_Buf_MD_Half"}
    Vs = GetDataVectors(join_vw+"|WACC", Flds, {"Return Options Array":"True"})

    //AM, quarter and half
    SetVs.[Walk_Qrtr_AM] = Round(Vs.[Walk_Buf_AM_Qrtr] / Vs.Area, 2)
    SetVs.[Walk_Half_AM] = Round(Vs.[Walk_Buf_AM_Half] / Vs.Area, 2) - SetVs.[Walk_Qrtr_AM]

    //MD, quarter and half
    SetVs.[Walk_Qrtr_MD] = Round(Vs.[Walk_Buf_MD_Qrtr] / Vs.Area, 2)
    SetVs.[Walk_Half_MD] = Round(Vs.[Walk_Buf_MD_Half] / Vs.Area, 2) - SetVs.[Walk_Qrtr_MD]

    SetDataVectors(join_vw+"|WACC", SetVs, )

	CloseView(join_vw)

//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )

    //Close the map
    CloseMap(map)


  Return(1)

quit:
    Return(0)

//EndStep
EndMacro

Macro "SEMCOG Stop Access" (Args)
    db_file = Args.[Highway DB]
    rs_file = Args.[Route System]
    taz_db = Args.[TAZ]
    taz_data_tb = Args.[TAZ Data Table]

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
    hwy_db_lyr = db_file + "|" + link_lyr

    {taz_lyr} = RunMacro("TCB Add DB Layers", taz_db)
    taz_db_lyr = taz_db + "|" + taz_lyr

//Create Map
   info = GetDBInfo(db_file)
   map = CreateMap("Map", {{"Scope", info[1]},{"Auto Project", "True"},{"Position", 100, 150}})
   map_name = GetMap()
   lyrs =AddRouteSystemLayer(map_name, "Bus Routes", rs_file, )
   RunMacro("Set Default RS Style", lyrs, "True", "True")

//Add Zone Layer
   zone_lyr = AddLayer(, "Zones", taz_db, "Zones", {{"False", "False"}})
   RunMacro("G30 new layer default settings", zone_lyr)
   setlayer("Zones")
   Det = SelectByQuery("Detroit", "Several", "Select * where County=1",)

// Fill all Access in Route Stops with zero
     Opts = null
     Opts.Input.[Dataview Set] = {rs_file+"|Route Stops", "Route Stops"}
     Opts.Global.Fields = {"Access"}
     Opts.Global.Method = "Value"
     Opts.Global.Parameter = {0}
     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     if !ret_value then goto quit

// Select those stops within Detroit
		  SetLayer("Route Stops")
		  SetSelectInclusion("Intersecting")
		  n = SelectbyVicinity("Selection", "Several", "Zones|Detroit", 0.0,)

// Join the route stops to the route system layer
     joinview = JoinViews("Jointview","Route Stops.Route_ID", "Bus Routes.Route_ID", {{"A", },{"Fields", aggr}})


// Select only stops in Detroit that are Inbound SMART and
     qry1 = 'Select * where RT_AUTHOR="SMART" and Direction="Inbound"'
     SEMCOGIn = selectbyquery("Selection", "Subset", qry1,)

//change Access to 2
     Opts = null
     Opts.Input.[Dataview Set] = {rs_file+"|Route Stops", "Route Stops", "Selection",}
     Opts.Global.Fields = {"Access"}
     Opts.Global.Method = "Value"
     Opts.Global.Parameter = {2}
     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     if !ret_value then goto quit

// Select those stops within Detroit
		  SetLayer("Route Stops")
		  SetSelectInclusion("Intersecting")
		  n = SelectbyVicinity("Selection", "Several", "Zones|Detroit", 0.0,)

// Select only stops in Detroit that are Outbound SMART and
     qry1 = 'Select * where RT_AUTHOR="SMART" and Direction="Outbound"'
     SEMCOGIn = selectbyquery("Selection", "Subset", qry1,)

//change Access to 1
     Opts = null
     Opts.Input.[Dataview Set] = {rs_file+"|Route Stops", "Route Stops", "Selection",}
     Opts.Global.Fields = {"Access"}
     Opts.Global.Method = "Value"
     Opts.Global.Parameter = {1}
     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     if !ret_value then goto quit

// Select those nodes that have "Park_Ride" <> null
// E7 Model: Not allowing wrong-direction SMART access at PnR nodes in Detroit.
/*
     SetLayer("Endpoints")
     ParkRide = selectbyquery("ParkRide", "Several", "Select * where PARK_RIDE<>null",)

// Select those stops where Park_Ride<>null
		  SetLayer("Route Stops")
		  SetSelectInclusion("Intersecting")
		  n = SelectbyVicinity("Selection", "Several", "Endpoints|ParkRide", 0.05,)

//change Access to 0
     Opts = null
     Opts.Input.[Dataview Set] = {rs_file+"|Route Stops", "Route Stops", "Selection",}
     Opts.Global.Fields = {"Access"}
     Opts.Global.Method = "Value"
     Opts.Global.Parameter = {0}
     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     if !ret_value then goto quit

     */

// Close all the maps
   maps = GetMapNames()
   for i = 1 to maps.length do
       CloseMap(maps[i])
   end

Return(ret_value)

quit:
         Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro

Macro "SEMCOG Build Highway Network" (Args)
// Build and set the Highway network
	shared nOper
        // Input Files
	db_file = Args.[Highway DB]
        // Output Files
	net_file = Args.[Network File]

	{node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
	ok = (node_lyr <> null & link_lyr <> null)
	if !ok then goto exit
	db_node_lyr = db_file + "|" + node_lyr
	db_link_lyr = db_file + "|" + link_lyr
	link_set_qry = "Select * where AB_DrvTime <> null | BA_DrvTime <> null"

	Opts = {	{"Input",   {{"Link Set",          	{db_link_lyr, link_lyr, "Selection", link_set_qry}}}},
	        	{"Global",  {{"Network Options",	{{"Node ID",         node_lyr + ".ID"},
                                                	{"Link ID",         link_lyr + ".ID"},
                                                	{"Turn Penalties",          "Yes"},
                                                	{"Keep Duplicate Links",    "FALSE"},
                                                	{"Ignore Link Direction",   "FALSE"}}},
                         	{"Link Options",		{{"Length",      link_lyr + ".Length",       link_lyr + ".Length"},
													{"Speed",       link_lyr + ".AB_FFS",       link_lyr + ".BA_FFS"},
													{"FF_Time",     link_lyr + ".AB_TIME",      link_lyr + ".BA_TIME"},         // free-flow time
                                                	{"AM_HwyT",     link_lyr + ".AB_AM_HwyT",   link_lyr + ".BA_AM_HwyT"},      // AM loaded time
                                                	{"MD_HwyT",     link_lyr + ".AB_MD_HwyT",   link_lyr + ".BA_MD_HwyT"},      // MD loaded time
                                                	{"PM_HwyT",     link_lyr + ".AB_PM_HwyT",   link_lyr + ".BA_PM_HwyT"},      // PM loaded time
                                                	{"EV_HwyT",     link_lyr + ".AB_EV_HwyT",   link_lyr + ".BA_EV_HwyT"},      // EV loaded time
													{"EA_HwyT",     link_lyr + ".AB_EA_HwyT",   link_lyr + ".BA_EA_HwyT"},      // EA loaded time
													{"AM_HwyC",     link_lyr + ".AB_AM_HwyC",   link_lyr + ".BA_AM_HwyC"},      // AM loaded generalized cost
                                                	{"MD_HwyC",     link_lyr + ".AB_MD_HwyC",   link_lyr + ".BA_MD_HwyC"},      // MD loaded generalized cost
                                                	{"PM_HwyC",     link_lyr + ".AB_PM_HwyC",   link_lyr + ".BA_PM_HwyC"},      // PM loaded generalized cost
                                                	{"EV_HwyC",     link_lyr + ".AB_EV_HwyC",   link_lyr + ".BA_EV_HwyC"},      // EV loaded generalized cost
                                                	{"EA_HwyC",     link_lyr + ".AB_EA_HwyC",   link_lyr + ".BA_EA_HwyC"},      // EA loaded generalized cost
													{"AMCap",       link_lyr + ".AB_AMCap",     link_lyr + ".BA_AMCap"},
                                                	{"MDCap",       link_lyr + ".AB_MDCap",     link_lyr + ".BA_MDCap"},
                                                	{"PMCap",       link_lyr + ".AB_PMCap",     link_lyr + ".BA_PMCap"},
                                                	{"EVCap",       link_lyr + ".AB_EVCap",     link_lyr + ".BA_EVCap"},
                                                	{"EACap",       link_lyr + ".AB_EACap",     link_lyr + ".BA_EACap"},
                                                	{"DYCap",       link_lyr + ".AB_DYCap",     link_lyr + ".BA_DYCap"},
													{"Alpha",       link_lyr + ".Alpha",        link_lyr + ".Alpha"},
													{"Beta",        link_lyr + ".Beta",         link_lyr + ".Beta"}}}}},
							{"Output",   			{{"Network File",      net_file}}}}
	//if !RunMacro("TCB Run Operation", nOper, "Build Highway Network", Opts) then goto exit
	RunMacro("TCB Run Operation", nOper, "Build Highway Network", Opts)
	nOper = nOper + 1

	SetStatus(2, "Setting centroid flags",)
	//====================================
	Opts = null
	Opts.Input.Database = db_file
	Opts.Input.Network = net_file
	Opts.Input.[Centroids Set] = {db_node_lyr, node_lyr, "Centroids", "Select * where Centroid <> null"}
	Opts.Input.[Spc Turn Pen Table] = {Args.[Turn_Pena]}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, 5}
	ok = RunMacro("TCB Run Operation", 1, "Highway Network Setting", Opts)
	if !ok then goto exit

	exit:
	SetStatus(2, "",)
	return(ok)
EndMacro

Macro "SEMCOG Build Transit Network" (Args)
// Build and set the Transit network
// Transit networks are built for each of 4 time periods
NextStep= "Define Files and Parameters"
SetStatus(1, NextStep, )
    shared nOper
    shared UT


    // Input Files
    db_file = Args.[Highway DB]
    rs_file = Args.[Route System]

    //Output Files
    tnw_files = UT.Expand(Args.[Transit Network])

    walk_qry = "Select * where Walktime <> null"
    drive_qry = "Select * where AB_DrvTime <> null | BA_DrvTime <> null"
    snap_node_fld = "Tagged_ID"
    stop_qry = "Select * where " + snap_node_fld + " <> null"


    Periods  = {"EA", "AM", "MD", "PM", "EV"}  //Build the transit network for 4 periods
    Modes    = {"LOC", "PRM", "MIX"}   // List of transit modes
    AccessModes  = {"WLK", "DRV", null, "DRVE"} //DRVE = Drive Egress

//EndStep
NextStep= "Build transit network"
SetStatus(1, NextStep, )

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
    ok = (node_lyr <> null & link_lyr <> null)
    if !ok then goto exit
    db_link_lyr = db_file + "|" + link_lyr
    db_node_lyr= db_file + "|" + node_lyr

    {rt_lyr, stop_lyr, ph_lyr} = RunMacro("TCB Add RS Layers", rs_file,"ALL",)
    rs_route_lyr = rs_file + "|" + rt_lyr
    stop_db = GetLayerDB(stop_lyr)
    db_stop_lyr = stop_db + "|" + stop_lyr

    TagRouteStopsWithNode(rt_lyr, null, snap_node_fld, 0.25)

    for _per = 1 to Periods.length do
        per = Periods[_per]

//EndStep
NextStep= "Build transit network - " + per
SetStatus(1, NextStep, )

        tnw_file = tnw_files[_per]
        if GetFileInfo(tnw_file) <> NULL then DeleteFile(tnw_file)

        Opts = null
        Opts.Input.[Transit RS] = rs_file
        Opts.Input.[RS Set] = {rs_route_lyr, rt_lyr, per+"_Routes", "Select * Where "+per+"_HDWY < 900"}
        Opts.Input.[Walk Link Set] = {db_link_lyr, link_lyr, "walk links", walk_qry}
        Opts.Input.[Stop Set] = {db_stop_lyr, stop_lyr, "stops", stop_qry}
        Opts.Input.[Drive Set] = {db_link_lyr, link_lyr, "Driving Links", drive_qry}

        Opts.Global.[Network Label] = "Transit Routes"
        Opts.Global.[Network Options].[Route Attributes].Ave_Fare = {rt_lyr + ".Ave_Fare"}
        Opts.Global.[Network Options].[Route Attributes].(per + "_HDWY")  = {rt_lyr + "." + per + "_HDWY"}

        Opts.Global.[Network Options].[Stop Attributes].FareZone = {stop_lyr + "." + "FAREZONE"}

        Opts.Global.[Network Options].[Stop Attributes].Access = {stop_lyr + ".Access"}  //Added by PB
        Opts.Global.[Network Options].[Stop Access] = stop_lyr + ".Access" // Added by PB
        //Opts.Flag.[Use Stop Access] = "Yes"    // Added by PB

        //Opts.Global.[Network Options].[Street Attributes].Length      = {link_lyr + ".Length",   link_lyr + ".Length"}
        //Opts.Global.[Network Options].[Street Attributes].("*_"+ period_s +"_IVTT_1") = {link_lyr + ".walktime", link_lyr + ".walktime"}
        //Opts.Global.[Network Options].[Street Attributes].("*_"+ period_s +"_IVTT_2") = {link_lyr + ".walktime", link_lyr + ".walktime"}
        //Opts.Global.[Network Options].[Street Attributes].("*_"+ period_s +"_IVTT_3") = {link_lyr + ".walktime", link_lyr + ".walktime"}  // Added by PB
        //Opts.Global.[Network Options].[Street Attributes].[*_DrvTime] = {link_lyr + ".AB_DrvTime", link_lyr + ".BA_DrvTime"}
        Opts.Global.[Network Options].[Street Attributes].[Length] = {link_lyr + ".Length",   link_lyr + ".Length"}
        Opts.Global.[Network Options].[Street Attributes].[*_DrvTime] = {link_lyr + ".AB_DrvTime", link_lyr + ".BA_DrvTime"}
        Opts.Global.[Network Options].[Street Attributes].("*_"+ per +"_IVTT_1") = {link_lyr + ".walktime", link_lyr + ".walktime"}
        Opts.Global.[Network Options].[Street Attributes].("*_"+ per +"_IVTT_2") = {link_lyr + ".walktime", link_lyr + ".walktime"}
        Opts.Global.[Network Options].[Street Attributes].("*_"+ per +"_IVTT_3") = {link_lyr + ".walktime", link_lyr + ".walktime"}

        link_atts = {{"Length",           {link_lyr + ".Length",                link_lyr + ".Length"},                "SUMFRAC"},
                     {"DriveTime",        {link_lyr + ".AB_DrvTime",            link_lyr + ".BA_DrvTime"},            "SUMFRAC"},
                     {(per+"_IVTT_1"),    {link_lyr + ".AB_" + per + "_IVTT_1", link_lyr + ".BA_" + per + "_IVTT_1"}, "SUMFRAC"},
                     {(per+"_IVTT_2"),    {link_lyr + ".AB_" + per + "_IVTT_2", link_lyr + ".BA_" + per + "_IVTT_2"}, "SUMFRAC"},
                     {(per+"_IVTT_3"),    {link_lyr + ".AB_" + per + "_IVTT_3", link_lyr + ".BA_" + per + "_IVTT_3"}, "SUMFRAC"}}

        Opts.Global.[Network Options].[Link Attributes] = link_atts

        Opts.Global.[Network Options].Walk = "Yes"

        Opts.Global.[Network Options].[Mode Field] = rt_lyr + ".MODE_ID"
        Opts.Global.[Network Options].[Walk Mode] = {link_lyr + ".MODE_ID", link_lyr + ".MODE_ID"}


        Opts.Global.[Network Options].TagField = snap_node_fld//Updated for TransCAD 7 AWalker Nov. 2016
        Opts.Global.[Network Options].[Merge Stops] = {stop_lyr + "." + "ID", stop_lyr + "." + snap_node_fld}//Updated for TransCAD 7 AWalker Nov. 2016

        Opts.Output.[Network File] = tnw_file

        ok = RunMacro("TCB Run Operation", nOper, "Build Transit Network", Opts)
        if !ok then goto exit
        nOper = nOper + 1


        //Run this once, setting up a network with classes
        ok = RunMacro("SEMCOG Set Transit Network",Args,per,Modes[1],AccessModes[1])//Added for Transit Drive Egress AWalker Nov. 2016
        if !ok then goto exit
    end //per in Periods

//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )

    exit:
    return(ok)
//EndStep
EndMacro

Macro "SEMCOG Set Transit Network" (Args, period_s, mode_t, access, globalxferwt) //Called from various other macros
// Set the Transit network parameters
//  - This macro is first called from build transit network to initialize all classes/settings
//  - This macro is called from skimming and assignment to choose the TNW class.
//  - SetStatus lines are not used here so they do not interfere with calling macros.
NextStep= "Define Files and Parameters"

    shared nOper

    //Available Period, Mode, and Access
    // period_s, mode_t, and access must be in these groups
    //Periods  = {"AM", "MD", "PM", "EV"}  //Not used since we have a separate network for each period
    Modes    = {"LOC", "PRM", "MIX", "All"}   // List of transit modes - includes additional "All" network that allows any mode.
    AccessModes  = {"WLK", "DRV", null, "DRVE", null} //DRVE = Drive Egress, null for KnR (no transit network)

    // Input Files
    db_file = Args.[Highway DB]
    rs_file = Args.[Route System]
    mode_tb = Args.[Mode Table]
    xfer_tb = Args.[Mode Transfer Table]
    para_tb = Args.[Transit Para Table]
    zone_fare = Args.[Zonal Fare]

    //Output Files
    praccess_template = Args.[PnR Access] //Use templates since loops use strings instead of indices
    pregress_template = Args.[PnR Egress]

    //TNW file to be set
    tnw_file = Args.[Transit Network]
    tnw_file = Substitute(tnw_file, "%PER_TRN%", period_s, )
    t = SplitPath(tnw_file)
    tnw_dir = t[1]+t[2]

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
    ok = (node_lyr <> null & link_lyr <> null)
    if !ok then goto exit
    db_node_lyr = db_file + "|" + node_lyr

    mode_vw = RunMacro("TCU Get File Name", mode_tb)
    xfer_vw = RunMacro("TCU Get File Name", xfer_tb)

//EndStep
NextStep= "Get parameters from table"

    //Get parameters from table
    para_vw = RunMacro("TCB OpenTable",,, {para_tb})
    ok = (para_vw <> null)  if !ok then goto exit
    vw = OpenTable("Parameters", "FFB", {para_tb})
    vecs = GetDataVectors(vw + "|", {"Variable", "Value"},)//Updated for TransCAD 7 AWalker Nov. 2016
    CloseView(vw)

    for i = 1 to vecs[1].length do
        Para.(vecs[1][i]) = vecs[2][i]//Updated for TransCAD 7 AWalker Nov. 2016
    end

    maxtransfers = Para.[Max. # of Transfers]
    valueoftime  = Para.[Value of Time]
    fare         = Para.[Fare]
    xfare        = Para.[Transfer Fare]

    iwaitweight     = Para.[Initial Wait Time Weight]
    xwaitweight     = Para.[Transfer Wait Time Weight]
    dwellweight    = Para.[Dwell Time Weight]
    walktimeweight = Para.[Walk Time Weight]
    drivetimeweight = Para.[Drive Time Weight]

    maxdrivetime    = Para.[Max Drive Time]
    transferpenalty = Para.[Transfer Penalty Time]
    maxwait         = Para.[Max Wait Time]
    minwait         = Para.[Min Wait Time]
    layover         = Para.[Layover Time]
    maxaccesstime   = Para.[Max Access Time]
    maxegresstime   = Para.[Max Egress Time]
    maxtransfertime = Para.[Max Transfer Time]
    maxtotalcost    = Para.[Max Total Cost]

    max_acces = Para.[Max Walk Access Paths]
    comb_factor = Para.[Combination Factor]

//EndStep
NextStep= "Define TNW classes"

    //Define TNW classes
    ClassNames = null
    imp_fld = null
    imp_mode = null
    hdwy_fld = null
    mode_used = null

    use_pnr = null
    use_pnr_walkacc = null
    max_acc_drive = null
    op_timecur = null
    op_distcur = null

    use_egr_pnr = null
    use_pnr_walkegr = null
    pd_timecur = null
    pd_distcur = null
    max_egr_drive = null

    for mod in Modes do
    for acc in AccessModes do
        //Skip KnR
        if acc = null then continue

        //Skip "All" unless walk access
        if mod = "All" and acc != "WLK" then continue

        ClassNames = ClassNames + {JoinStrings({period_s, mod, acc}, "_")}

        //Choose period and transit mode based on scnario manager template
        op_mat_file = Substitute(praccess_template, "%PER_TRN%", period_s, )
        op_mat_file = Substitute(op_mat_file, "%TMODE%", mod, )

        pd_mat_file = Substitute(pregress_template, "%PER_TRN%", period_s, )
        pd_mat_file = Substitute(pd_mat_file, "%TMODE%", mod, )

        //IVTT and headway fields, period-specific
        imp_fld = imp_fld + {period_s+"_IVTT_1"}
        imp_mode = imp_mode + {period_s + "_ImpFld"}
        hdwy_fld = hdwy_fld + {period_s+"_HDWY"}

        //Mode used and weight fields (mod specific)
        mode_used = mode_used + {"USE_"+mod}
        if mod = "All" then mode_ivtt = mode_ivtt + {null}  //no special weight for all mode network
        else mode_ivtt = mode_ivtt + {"WT_"+mod}

        //Drive / PnR Settings
        if acc = "DRV" and GetFileInfo(op_mat_file) != null then do
            //PnR Access
            use_pnr = use_pnr + {"Yes"}
            use_pnr_walkacc = use_pnr_walkacc + {"No"}
            max_acc_drive = max_acc_drive + {maxdrivetime}
            op_timecur = op_timecur + {{op_mat_file, "Drive Time", "Origin", "Parking"}}
            op_distcur = op_distcur + {{op_mat_file, "Miles", "Origin", "Parking"}}

            //Pnr Egress
            use_egr_pnr = use_egr_pnr + {"No"}
            use_pnr_walkegr = use_pnr_walkegr + {"No"}
            pd_timecur = pd_timecur + {}
            pd_distcur = pd_distcur + {}
            max_egr_drive = max_egr_drive + {}

        end else if acc = "DRVE" and GetFileInfo(pd_mat_file) != null then do
            //PnR Access
            use_pnr = use_pnr + {"No"}
            use_pnr_walkacc = use_pnr_walkacc + {"No"}
            max_acc_drive = max_acc_drive + {}
            op_timecur = op_timecur + {}
            op_distcur = op_distcur + {}

            //Pnr Egress
            use_egr_pnr = use_egr_pnr + {"Yes"}
            use_pnr_walkegr = use_pnr_walkegr + {"No"}
            max_egr_drive = max_egr_drive + {maxdrivetime}
            pd_timecur = pd_timecur + {{pd_mat_file, "Drive Time", "Origin", "Parking"}}
            pd_distcur = pd_distcur + {{pd_mat_file, "Miles", "Origin", "Parking"}}
        end else do
            //PnR Access
            use_pnr = use_pnr + {"No"}
            use_pnr_walkacc = use_pnr_walkacc + {}
            max_acc_drive = max_acc_drive + {}
            op_timecur = op_timecur + {}
            op_distcur = op_distcur + {}
            //Pnr Egress
            use_egr_pnr = use_egr_pnr + {"No"}
            use_pnr_walkegr = use_pnr_walkegr + {}
            pd_timecur = pd_timecur + {}
            pd_distcur = pd_distcur + {}
            max_egr_drive = max_egr_drive + {}
        end

    end
    end
    CurClass = JoinStrings({period_s, mode_t, access}, "_")

//EndStep
NextStep= "Define Network Settings"

    // set parameters
    Opts = null
    Opts.Input.[Fare Currency] = {zone_fare, "Fare (mode 22)", "Rows", "Columns"}
    Opts.Input.[Transit RS] = rs_file
    Opts.Input.[Transit Network] = tnw_file
    Opts.Input.[Centroid Set] = {db_node_lyr, node_lyr, "Centroids", "Select * where Centroid <> null"}

    // mode table settings
    Opts.Flag.[Use Mode] = "Yes"
    Opts.Input.[Mode Table] = {mode_tb}
    Opts.Flag.[Combine By Mode] = "Yes"//Updated for TransCAD 7 AWalker Nov. 2016
    Opts.Input.[Mode Cost Table] = {xfer_tb}
    Opts.Field.[Mode Used]      = mode_used //Updated for TransCAD 7 AWalker Nov. 2016
    Opts.Field.[Mode Impedance] = imp_mode
    //Opts.Field.[Mode Speed]     = mode_vw + ".SPEED"
    Opts.Field.[Mode Xfer Fare] = "XferFare"  // removed by PB - move back by Jchen in May 2015
    Opts.Field.[Mode Fare Type] = "Fare_Type"
    Opts.Field.[Mode Max IWait] = "Max_IWait"  // removed by PB - move back by JChen in May 2015
    Opts.Field.[Mode Max XWait] = "Max_XWait"  // removed by PB - move back by JChen in May 2015
    Opts.Field.[Mode Fare Core] = "Fare_Core"
    Opts.Field.[Mode Imp Weight] = mode_ivtt

    // mode-to-mode transfer table settings	cjl012009
    Opts.Flag.[Use Mode Cost] = "Yes"
    Opts.Field.[Inter-Mode Xfer From] = "FROM"
    Opts.Field.[Inter-Mode Xfer To]   = "TO"
    Opts.Field.[Inter-Mode Xfer Stop] = "STOP"
    Opts.Field.[Inter-Mode Xfer Proh] = "Prohibit"
    Opts.Field.[Inter-Mode Xfer Wait] = "Wait"
    Opts.Field.[Inter-Mode Xfer Fare] = "XferFare"

    Opts.Field.[Link Impedance] = imp_fld
    Opts.Field.[Route Fare] = "Ave_Fare"
    Opts.Field.[Route Headway] = hdwy_fld
    Opts.Field.[Stop Zone ID] = "FAREZONE"

    Opts.Global.[Class Names] = ClassNames         //Updated for TransCAD 7 AWalker Nov. 2016
    Opts.Global.[Class Description] = ClassNames
    Opts.Global.[current class] = CurClass

    Opts.Global.[Value of Time] = valueoftime
    Opts.Global.[Max Xfer Number] = r2i(maxtransfers)
    Opts.Global.[Global Max WACC Path] = r2i(max_acces)
    Opts.Global.[Path Threshold] = comb_factor

    Opts.Global.[Global Fare Type] = 1		//flat fare
    Opts.Global.[Zonal Fare Method] = 1	//the zonal fare is applied by Route
    Opts.Flag.[Fare System] = 3             // Mixed fare

    Opts.Global.[Global Fare Value] = fare
    Opts.Global.[Global Xfer Fare] = xfare
    Opts.Global.[Global Fare Core] = "Fare (mode 24)" //TC8 suggests using core name instead of index, also works in TC7.

    Opts.Global.[Global IWait Weight] = iwaitweight
    Opts.Global.[Global XWait Weight] = xwaitweight
	Opts.Global.[Global Xfer Weight] = globalxferwt   // added to create Local+Premium with xfer skims
    Opts.Global.[Global Dwell Weight] = dwellweight
    Opts.Global.[Walk Weight] = walktimeweight
    Opts.Global.[Drive Time Weight] = drivetimeweight
    //Opts.Global.[Global Dwell Time]   = 0.32
    Opts.Global.[Global Dwell On Time] = 0.16//Updated for TransCAD 7 AWalker Nov. 2016
    Opts.Global.[Global Dwell Off Time] = 0.16

    Opts.Global.[Global Xfer Time] = transferpenalty
    Opts.Global.[Global Max IWait] = maxwait
    Opts.Global.[Global Max XWait] = maxwait
    Opts.Global.[Global Min IWait] = minwait
    Opts.Global.[Global Min XWait] = minwait
    Opts.Global.[Global Layover Time] = layover
    Opts.Global.[Global Max Access] = maxaccesstime
    Opts.Global.[Global Max Egress] = maxegresstime
    Opts.Global.[Global Max Transfer] = maxtransfertime
    //Opts.Global.[Max Trip Time] = maxtotalcost      // max. total path cost //Removed for Transit Validation AWalker Nov. 2016

    Opts.Flag.[Use Transit Access]  = "No"
    Opts.Flag.[Use All Walk Path]   = "No"

    //Enable stop access/egress restrictions
    Opts.Field.[Stop Access] = "Access"
    Opts.Flag.[Use Stop Access] = "Yes"

//EndStep
NextStep= "Define Network Settings (Drive)"

    //Drive mode settings (all class-based)

    //Drive Access
    Opts.Input.[OP Time Currencies] = op_timecur //currencies option must be plural for multiple classes
    Opts.Input.[OP Dist Currencies] = op_distcur

    Opts.Flag.[Use Park and Ride] = use_pnr
    Opts.Flag.[Use P&R Walk Access] = use_pnr_walkacc
    Opts.Global.[Max Acce Drive Time] = max_acc_drive


    //Drive Egress
    Opts.Input.[PD Time Currencies] = pd_timecur
    Opts.Input.[PD Dist Currencies] = pd_distcur
    Opts.Flag.[Use Egress Park and Ride]  = use_egr_pnr
    Opts.Flag.[Use P&R Walk Egress] = use_pnr_walkegr
    Opts.Global.[Max Egre Drive Time] = max_egr_drive

//EndStep
NextStep= "Apply Network Settings"

    ok = RunMacro("TCB Run Operation", nOper, "Transit Network Setting PF", Opts)
    if !ok then goto exit
    nOper = nOper + 1

//EndStep
NextStep= "Clean Up"

    exit:
    return(ok)
//EndStep
EndMacro


//====== Network Skimming ======//

Macro "SEMCOG Highway Skimming" (Args)

NextStep= "Define files and data"
SetStatus(1, NextStep, )

    shared nOper
    shared UT, Scen //Scen for feedback information

    // Input Files
    highway_db = Args.[Highway DB]
    net_file = Args.[Network File]
    term_file = Args.[Term Time Lookup]
    extern_file = Args.[External Params]

    //Intermediate Files
    sed_file = Args.[TAZ Land Use Data]

    //Output Files
    skim_files = UT.Expand(Args.HwySkims)
    fb_skim_files = {Substitute(Args.HwySkims, "%PER_HWY%", "AM", ),
                     Substitute(Args.HwySkims, "%PER_HWY%", "MD", ),
                     Substitute(Args.HwySkims, "%PER_HWY%", "PM", )
                     }
    fb_report_file = Args.[Feedback Report]
    // Parameters
    intrazonalfactor = Args.[IntrazonalFactor]
    intrazonalneighbors = r2i(Args.[IntrazonalNeighbors])
    Periods = Args.HwyPeriods
    FeedbackConv = Args.FeedbackConv

//EndStep
NextStep= "Feedback Initial Check"
SetStatus(1, NextStep, )

    //If running feedback and on iteration past 1, copy previous skims to "_prev" files
    if Scen.Feedback.run and Scen.Feedback.iteration > 1 then do
        for ii = 1 to fb_skim_files.length do
            skim_file = fb_skim_files[ii]
            t = SplitPath(skim_file)
            prev_file = t[1]+t[2]+t[3]+"_prev"+t[4]

            if GetFileInfo(prev_file) != null then DeleteFile(prev_file)
            RenameFile(skim_file, prev_file)
        end
    end

//EndStep
NextStep= "Running Highway Skim"
SetStatus(1, NextStep, )

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", highway_db)
    ok = (node_lyr <> null)     if !ok then goto exit
    db_lyr = highway_db + "|" + node_lyr

    cent_qry = "Select * where Centroid <> null"



    // STEP 1: TCSPMAT
    SkimOpts = {{"Input",    {{"Network",           net_file},
                              {"Origin Set",        {db_lyr,node_lyr, "centroid", cent_qry}},
                              {"Destination Set",   {db_lyr, node_lyr, "centroid"}},
                              {"Via Set",           {db_lyr,node_lyr}}}},
                {"Field",    {{"Nodes",             node_lyr + ".ID"}}},
                {"Global",   {{"Output Type",       "Matrix"}}},
                {"Output",   {{"Output Matrix",    {{"Label", "Shortest Path"}}}}}}

    IntraOpts = {{"Input",    {{"Matrix Currency",   }}},
                 {"Global",   {{"Factor",            intrazonalfactor},
                               {"Neighbors",         intrazonalneighbors},
                               {"Operation",         1},
                               {"Treat Missing",     1}}}}

	CreateProgressBar("Skimming", "TRUE")
	for ii = 1 to Periods.length do
		period = Periods[ii]
        pkop = if (period = "AM" or period = "PM") then "PK" else "OP"


//EndStep
NextStep= "Check for HOV Lanes"
SetStatus(1, NextStep, )

        {HOV2_links_qry, HOV3_links_qry, SOV_LT_links_qry, MT_HT_links_qry, nonMotLinks_qry} = RunMacro("GetExclusionQueries", null, period)
        SetLayer(link_lyr)
        excl_sov = SelectByQuery("ExSOV", "Several", SOV_LT_links_qry)
        excl_hov2 = SelectByQuery("ExHOV2", "Several", HOV2_links_qry)
        excl_hov3 = SelectByQuery("ExHOV3", "Several", HOV3_links_qry)

        cnt_hov2 = SetXOR("HOV2_only", {"ExSOV", "ExHOV2"})  //Find links where HOV2 are allowed, but not SOV (i.e., SOV and HOV2 exclusion sets are different)
        cnt_hov3 = SetXOR("HOV3_only", {"ExHOV2", "ExHOV3"}) //Find links where HOV3 are allowed, but not HOV2 (i.e., HOV2 and HOV3 exclusion sets are different)


        //HOV_Settings: {{skim_file, disable_qry (or null), Progress indicator}}
		//** Commenting out conditions for producing the HOV2 and HOV3 skims all the time, regardless of the existance of HOV links.

        HOV_Settings = {{skim_files[ii], "ExSOV", "SOV"}}

        t = SplitPath(skim_files[ii])
        sk2_file = t[1]+t[2]+t[3]+"_HOV2"+t[4]
		HOV_Settings = HOV_Settings + {{sk2_file, "ExHOV2", "HOV2"}}

        t = SplitPath(skim_files[ii])
        sk3_file = t[1]+t[2]+t[3]+"_HOV3"+t[4]
		HOV_Settings = HOV_Settings + {{sk3_file, "ExHOV3", "HOV3"}}

        UpdateProgressBar("Skimming:  " + period, r2i(ii * 20))
        for jj = 1 to HOV_Settings.length do


//EndStep
NextStep= "Running Highway Skim - " + period + " " + HOV_Settings[jj][3]
SetStatus(1, NextStep, )

            skim_mat = HOV_Settings[jj][1]
            Opts = CopyArray(SkimOpts)

            //Disable excluded links
            if HOV_Settings[jj][2] != null then do
                t = SplitPath(net_file)
                use_net = t[1]+t[2]+"__TEMP__NET.net"
                CopyFile(net_file, use_net)

                ActiveNetwork = ReadNetwork(use_net)
                id_spec = link_lyr+".ID"
                ChangeLinkStatus(ActiveNetwork, link_lyr+"|"+HOV_Settings[jj][2], {[Link ID]:id_spec, Type:"Disable"})
                ActiveNetwork = null

                Opts.Input.Network = use_net
            end //Disable some links

            //Else, Original Opts are retained.


            Opts.Field.Minimize = period + "_" + "HwyC"             // build path minimizing generalized cost
            Opts.Field.[Skim Fields] = {{"Length",              "All"},     // skim on distance and time
                                    {period + "_" + "HwyT", "All"}}
            Opts.Output.[Output Matrix].[File Name] = skim_mat

            // Calculate shortest paths and distances in miles
            ok = RunMacro("TCB Run Procedure", nOper, "TCSPMAT", Opts)
            if !ok then goto exit
            nOper = nOper + 1

            if HOV_Settings[jj][2] != null then do
                UT.Delete(use_net)
            end

            // rename the skimmed matrix core
            skim_m = RunMacro("TCB OpenMatrix", skim_mat,)
            ok = (skim_m <> null)  if !ok then goto exit

            time_core = "Trav_Time"
            CoreNames = GetMatrixCoreNames(skim_m)
            CoreNames[2] = "Miles"          // set skimmed length core name to "Miles"
            CoreNames[3] = time_core        // set skimmed time core name to "Trav_Time"
            SetMatrixCoreNames(skim_m, CoreNames)      // NOTE: first core name is period + _HwyC

            // Add the intrazonal travel times
            Opts = CopyArray(IntraOpts)
            Opts.Input.[Matrix Currency] = {skim_mat, time_core, "Origin","Destination"}

            ok = RunMacro("TCB Run Procedure", nOper, "Intrazonal", Opts)
            if !ok then goto exit

            // Add the intrazonal distances
            Opts.Input.[Matrix Currency] = {skim_mat, "Miles", "Origin","Destination"}

            ok = RunMacro("TCB Run Procedure", nOper, "Intrazonal", Opts)
            if !ok then goto exit
            nOper = nOper + 1

            // Add matrix cores
            AddMatrixCore(skim_m, "Term_Time")
            AddMatrixCore(skim_m, "SP_and_Terminal")
            AddMatrixCore(skim_m, "Miles (orig)")

            // add matrix index mapping node id to zone id
            ok = RunMacro("Add Matrix Zone ID Index", skim_mat, Args)
            if !ok then goto exit

			//************ Write OMX Skims **************
			skim_curs = CreateMatrixCurrencies(skim_m, GetMatrixBaseIndex(skim_m).[0], GetMatrixBaseIndex(skim_m).[1], )
			cores = GetMatrixCoreNames(skim_m)
			for c in cores do
				skim_curs.(c) := nz(skim_curs.(c))
			end
			omx_file = Substitute(skim_mat, ".mtx", ".omx", )
            copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 0}
            CopyMatrix(skim_curs[1][2], copy_matrix_options)

//EndStep
NextStep= "Add terminal times to skim matrix - " + period
SetStatus(1, NextStep, )

    		//========================================================
    		// Apply origin/destination terminal time lookup
    		term_vw = RunMacro("TCB OpenTable",,, {term_file})
    		ok = (term_vw <> null)  if !ok then goto exit

            sed_vw =  RunMacro("TCB OpenTable",,, {sed_file})
    		ok = (sed_vw <> null)  if !ok then goto exit

    		join_vw = JoinViews("sed+term", sed_vw+".AreaType", term_vw+".AT",)
            {P, A} = GetDataVectors(join_vw+"|", {pkop+"_P", pkop+"_A"}, {{"Sort Order", {{"ZONE", "Ascending"}}}})
            P.RowBased = False
            A.RowBased = True
            skim_curs = CreateMatrixCurrencies(skim_m, "ZoneID", "ZoneID", ) //Index by zone ID, not node ID
            skim_curs.Term_Time := nz(P) + nz(A)
            skim_curs.SP_and_Terminal := skim_curs.(time_core) + skim_curs.Term_Time

            CloseView(join_vw)


//EndStep
NextStep= "Adjust external distances - " + period
SetStatus(1, NextStep, )

            //Save original distances
            skim_curs.[Miles (orig)] := skim_curs.Miles

            //    Requires zone numbers to be sequential.  Non-sequential zones would require
            //    additonal indexing/lookup.  Sequential zones are assumed elsewhere, so not
            //    allowing for non-sequential here.

            V = Vector(skim_curs.Miles.Rows, "Double", {{"Constant", 0}})

            extern_vw = OpenTable("ExternalParams", "FFB", {extern_file})

            SetView(extern_vw)
            cnt = SelectByQuery("LenPen", "Several", "Select * Where LENGTH_PEN > 0", )
            if cnt > 0 then do

                {ZONE, PEN} = GetDataVectors(extern_vw+"|LenPen", {"ID", "LENGTH_PEN"}, )

                for zz = 1 to ZONE.length do

                    V[ZONE[zz]] = PEN[zz]

                end

            end

            V.Rowbased = "True"
            skim_curs.Miles := skim_curs.Miles + V
            V.Rowbased = "False"
            skim_curs.Miles := skim_curs.Miles + V

//EndStep
NextStep= "Set all EE trip interchanges to null - " + period
SetStatus(1, NextStep, )

            // add matrix index for external zones (using ID)
            join_vw = JoinViews("Nodes+sed", node_lyr+".CENTROID", sed_vw+".zoneid", )
            SetView(join_vw)
            SelectByQuery("External", "Several", "Select * Where External > 0", )
            CreateMatrixIndex("External", skim_m, "Both", join_vw+"|External", node_lyr+".ID", "CENTROID", )

            ext_cur = CreateMatrixCurrency(skim_m, "SP_and_Terminal", "External", "External", )
            ext_cur := null
            ext_cur = null

            CloseView(join_vw)

            skim_curs = null
            skim_m = null

        end //end of HOV class loop jj
    end  // end of period loop ii

//EndStep
NextStep= "Check Speed Feedback Convergence"
SetStatus(1, NextStep, )

	//Check feedback convergence
	if Scen.Feedback.iteration > 1 then do
		dim RMSE_array[fb_skim_files.length]

		//Loop over off-peak and peak
		for ii = 1 to fb_skim_files.length do
            tmp = SplitPath(fb_skim_files[ii])
			prev_skim_file = tmp[1]+tmp[2]+tmp[3]+"_prev"+tmp[4]

            //Open previous and current skim file
            c_mat = OpenMatrix(fb_skim_files[ii], )
            p_mat = OpenMatrix(prev_skim_file, )
            c_cur = CreateMatrixCurrency(c_mat, "SP_and_Terminal", , , )
            p_cur = CreateMatrixCurrency(p_mat, "SP_and_Terminal", , , )

            //Compare skims
            mstats = MatrixRMSE(p_cur, c_cur)
            rmse = mstats.RMSE
            pctrmse = mstats.RelRMSE

            RMSE_array[ii] = pctrmse

            //Close matrices
            c_cur = null
            p_cur = null
            c_mat = null
            p_mat = null

            //Delete the previous skim matrix
            DeleteFile(prev_skim_file)
		end //end ii loop AM, MD, PM


        //Save feedback info for display in the progress bar
        if RMSE_array[1] = null and RMSE_array[2] = null then fb_gap = null
        else fb_gap = format(RMSE_array[1]/100, "*0.0%") + " / " + format(RMSE_array[2]/100, "*0.0%") + " / " + format(RMSE_array[3]/100, "*0.0%")

        //Save feedback info into a text file and in an array for the performance report
        tmp = SplitPath(flow_files)

        t = SplitPath(fb_report_file)
        fb_array_file  = t[1]+t[2]+t[3]+".arr"

        if Scen.Feedback.iteration = 2 then do
            fp = OpenFile(fb_report_file, "w")
            WriteLine(fp, "Speed Feedback Report")
            WriteLine(fp, "-------------------------------------------")
            WriteLine(fp, "Iteration           AM %RMSE            MD %RMSE            PM %RMSE")

            //Empty array file
            fb_array = {{,,}}
            SaveArray(fb_array, fb_array_file)
        end else do
            fp = OpenFile(fb_report_file, "a")
        end

        WriteLine(fp, rpad(format(Scen.Feedback.iteration, "*."), 20) +
                    rpad(format(RMSE_array[1]/100, "*0.0000%"), 20) +
                    rpad(format(RMSE_array[2]/100, "*0.0000%"), 20) +
                    rpad(format(RMSE_array[3]/100, "*0.0000%"), 20))

        //Check for convergence
        if FeedbackConv > 0 and RMSE_array[1] < FeedbackConv and RMSE_array[1] < FeedbackConv then do
            WriteLine(fp, "*** Feedback Converged ***")
            Scen.Feedback.converged = True
        end

        fb_array = LoadArray(fb_array_file)
        fb_array = fb_array + {{Scen.Feedback.iteration, RMSE_array[1], RMSE_array[2]}}
        SaveArray(fb_array, fb_array_file)

        CloseFile(fp)
    end //end if feedback iteration > 1

//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
    DestroyProgressBar()

    exit:
    Return(ok)
//EndStep
EndMacro

Macro "SEMCOG Non Motorized Skimming" (Args)

NextStep= "Define files and data"
SetStatus(1, NextStep, )

    shared nOper
    shared UT, Scen //Scen for feedback information

    // Input Files
    highway_db = Args.[Highway DB]
    net_file = Args.[Network File]

    //Output Files
	nm_skim_files = Substitute(Args.HwySkims, "%PER_HWY%_HwySkim", "NM_Skim", )

    // Parameters
    intrazonalfactor = Args.[IntrazonalFactor]
    intrazonalneighbors = r2i(Args.[IntrazonalNeighbors])
    Periods = Args.HwyPeriods
    FeedbackConv = Args.FeedbackConv

//EndStep
NextStep= "Running Non Motorized Skim"
SetStatus(1, NextStep, )

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", highway_db)
    ok = (node_lyr <> null)     if !ok then goto exit
    db_lyr = highway_db + "|" + node_lyr

    cent_qry = "Select * where Centroid <> null"



    // STEP 1: TCSPMAT
    SkimOpts = {{"Input",    {{"Network",           net_file},
                              {"Origin Set",        {db_lyr,node_lyr, "centroid", cent_qry}},
                              {"Destination Set",   {db_lyr, node_lyr, "centroid"}},
                              {"Via Set",           {db_lyr,node_lyr}}}},
                {"Field",    {{"Nodes",             node_lyr + ".ID"}}},
                {"Global",   {{"Output Type",       "Matrix"}}},
                {"Output",   {{"Output Matrix",    {{"Label", "Shortest Path"}}}}}}

    IntraOpts = {{"Input",    {{"Matrix Currency",   }}},
                 {"Global",   {{"Factor",            intrazonalfactor},
                               {"Neighbors",         intrazonalneighbors},
                               {"Operation",         1},
                               {"Treat Missing",     1}}}}

    CreateProgressBar("Skimming", "TRUE")

//EndStep
NextStep= "Check for NM Lanes"
SetStatus(1, NextStep, )

        {HOV2_links_qry, HOV3_links_qry, SOV_LT_links_qry, MT_HT_links_qry, nonMotLinks_qry} = RunMacro("GetExclusionQueries", null, period)
        SetLayer(link_lyr)

		excl_nonmot = SelectByQuery("ExNM", "Several", nonMotLinks_qry) // non motorized exclusion links: links where NM is not allowed (e.g. freeway, ramps, transit only etc.)


        //NM_Settings: {{skim_file, disable_qry (or null), Progress indicator}}
        NM_Settings = {nm_skim_files, "ExNM", "NM"}

//EndStep
NextStep= "Running Non Motorized Skim - " + NM_Settings[3]
SetStatus(1, NextStep, )

            skim_mat = NM_Settings[1]
            Opts = CopyArray(SkimOpts)

            //Disable excluded links
            if NM_Settings != null then do
                t = SplitPath(net_file)
                use_net = t[1]+t[2]+"__TEMP__NET.net"
                CopyFile(net_file, use_net)

                ActiveNetwork = ReadNetwork(use_net)
                id_spec = link_lyr+".ID"
                ChangeLinkStatus(ActiveNetwork, link_lyr+"|"+NM_Settings[2], {[Link ID]:id_spec, Type:"Disable"})
                ActiveNetwork = null

                Opts.Input.Network = use_net
            end //Disable some links

            //Else, Original Opts are retained.


            Opts.Field.Minimize = "Length"             // build path minimizing generalized cost
            Opts.Field.[Skim Fields] = {{"Length", "All"},{"Length", "All"}}     // skim on distance
            Opts.Output.[Output Matrix].[File Name] = skim_mat
            //Opts.Output.[Output Matrix].[OMX] = "TRUE"

            // Calculate shortest paths and distances in miles
            ok = RunMacro("TCB Run Procedure", nOper, "TCSPMAT", Opts)
            if !ok then goto exit
            nOper = nOper + 1

            if NM_Settings[2] != null then do
                UT.Delete(use_net)
            end

            // rename the skimmed matrix core
            skim_m = RunMacro("TCB OpenMatrix", skim_mat,)
            ok = (skim_m <> null)  if !ok then goto exit

            CoreNames = GetMatrixCoreNames(skim_m)
            CoreNames[1] = "DISTWALK"
            CoreNames[2] = "DISTBIKE"
            SetMatrixCoreNames(skim_m, CoreNames)

            // Add the intrazonal distances
            Opts = CopyArray(IntraOpts)
            Opts.Input.[Matrix Currency] = {skim_mat, "DISTWALK", "Origin", "Destination"}

            ok = RunMacro("TCB Run Procedure", nOper, "Intrazonal", Opts)
            if !ok then goto exit
            nOper = nOper + 1

            // Add the intrazonal distances
			Opts = CopyArray(IntraOpts)
            Opts.Input.[Matrix Currency] = {skim_mat, "DISTBIKE", "Origin", "Destination"}

            ok = RunMacro("TCB Run Procedure", nOper, "Intrazonal", Opts)
            if !ok then goto exit
            nOper = nOper + 1

            // add matrix index mapping node id to zone id
            ok = RunMacro("Add Matrix Zone ID Index", skim_mat, Args)
            if !ok then goto exit


			//************ Write OMX Skims **************
			curs = CreateMatrixCurrencies(skim_m, GetMatrixBaseIndex(skim_m).[0], GetMatrixBaseIndex(skim_m).[1], )
			cores = GetMatrixCoreNames(skim_m)
			for c in cores do
				curs.(c) := nz(curs.(c))
			end
            omx_file = Substitute(skim_mat, ".mtx", ".omx", )
            copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 1}
            CopyMatrix(curs[1][2], copy_matrix_options)

			//***********create the DIST core where all links are available
			nm_all_links = Substitute(Args.HwySkims, "%PER_HWY%_HwySkim", "NM_Skim_All", )
			Opts = CopyArray(SkimOpts)
			Opts.Input.Network = net_file
			Opts.Field.Minimize = "Length"             // build path minimizing generalized cost
            Opts.Field.[Skim Fields] = {"Length", "All"}     // skim on distance
            Opts.Output.[Output Matrix].[File Name] = nm_all_links

            // Calculate shortest paths and distances in miles
            ok = RunMacro("TCB Run Procedure", nOper, "TCSPMAT", Opts)
            if !ok then goto exit
            nOper = nOper + 1

			// rename the skimmed matrix core
            skim_m = RunMacro("TCB OpenMatrix", nm_all_links,)
            ok = (skim_m <> null)  if !ok then goto exit

            CoreNames = GetMatrixCoreNames(skim_m)
            CoreNames[1] = "DIST"
            SetMatrixCoreNames(skim_m, CoreNames)

			// Add the intrazonal distances
            Opts = CopyArray(IntraOpts)
            Opts.Input.[Matrix Currency] = {nm_all_links, "DIST", "Origin", "Destination"}

            ok = RunMacro("TCB Run Procedure", nOper, "Intrazonal", Opts)
            if !ok then goto exit
            nOper = nOper + 1

            // add matrix index mapping node id to zone id
            ok = RunMacro("Add Matrix Zone ID Index", nm_all_links, Args)
            if !ok then goto exit


			//************ Write OMX Skims **************
			curs = CreateMatrixCurrencies(skim_m, GetMatrixBaseIndex(skim_m).[0], GetMatrixBaseIndex(skim_m).[1], )
			cores = GetMatrixCoreNames(skim_m)
				for c in cores do
					curs.(c) := nz(curs.(c))
				end
            omx_file = Substitute(nm_all_links, ".mtx", ".omx", )
            copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 1}
            CopyMatrix(curs[1][2], copy_matrix_options)
//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
    DestroyProgressBar()

    exit:
    Return(ok)
//EndStep
EndMacro

Macro "SEMCOG PR Access" (Args)
// Creating Park and Ride Access Skims
    	shared nOper
        shared UT


    	// Input Files
    	highway_db = Args.[Highway DB]
    	net_file = Args.[Network File]
        praccess_template = Args.[PnR Access] //Use templates since loops use strings instead of indices

    	{node_lyr} = RunMacro("TCB Add DB Layers", highway_db)
    	ok = (node_lyr <> null)     if !ok then goto exit
    	db_lyr = highway_db + "|" + node_lyr

    	CreateProgressBar("Skimming", "TRUE")
    	Periods  = {"EA", "AM", "MD", "PM", "EV"}		//4 periods by JChen in July 2015
        pnrModes = {"LOC", "PRM", "MIX"}   // List of DRV transit modes

        //get node layer fields (to test for available PnR fields)
        {node_flds, } = GetFields(node_lyr, "All")

    	for i =1 to Periods.length do
    	   for j =1 to pnrModes.length do
	     period = Periods[i]
	     mode = pnrModes[j]

     	     SetStatus(2, "Computing " + " PR Access",)
        	//===================================================
        	UpdateProgressBar("Skimming:  " + period + "   " + mode, r2i(i * 25))

            //Choose period and transit mode based on scnario manager template
            skim_mat = Substitute(praccess_template, "%PER_TRN%", period, )
            skim_mat = Substitute(skim_mat, "%TMODE%", mode, )

    		cent_qry = "Select * where Centroid <> null"

            //Use mode-specific park and ride only if field is present
            if ArrayPosition(node_flds, {mode+"_PNR"}, ) > 0 then do
                pnr_fld = mode+"_PNR"
            end else do
                pnr_fld = "PARK_RIDE"
            end
    		plot_qry = "Select * where " + pnr_fld + " > 0"

    		SkimOpts = {{"Input",   {{"Network",           net_file},
                             {"Origin Set",        {db_lyr, node_lyr, "centroid", cent_qry}},
                             {"Destination Set",   {db_lyr, node_lyr,  "Parking Nodes", plot_qry}},
                             {"Via Set",           {db_lyr, node_lyr}}}},
                {"Field",   {{"Nodes",             node_lyr + ".ID"}}},
                {"Global",  {{"Output Type",       "Matrix"}}}}


        	Opts = CopyArray(SkimOpts)
        	Opts.Field.Minimize = period + "_" + "HwyC"             // build path minimizing generalized cost
        	Opts.Field.[Skim Fields] = {{"Length",              "All"},     // skim on distance and time	cjl122008
        	                            {period + "_" + "HwyT", "All"}}
		Opts.Output.[Output Matrix].Label = period + " PR Access"
        	Opts.Output.[Output Matrix].[File Name] = skim_mat

        	ok = RunMacro("TCB Run Procedure", nOper, "TCSPMAT", Opts)
        	if !ok then goto exit

        	nOper = nOper + 1
        	skim_m = RunMacro("TCB OpenMatrix", skim_mat,)
        	ok = (skim_m <> null)  if !ok then goto exit
        	SetMatrixCoreNames(skim_m, {"Cost", "Miles", "Drive Time"})		//cjl122008
		SetMatrixIndexName(skim_m, "Destination", "Parking")
    	end // end of pnr mode loop j
    	end // end of time period loop i
	skim_m = null
        ok = RunMacro("SEMCOG PR Egress", Args) //Added for Transit Drive Egress AWalker Nov. 2016
        if !ok then goto exit
        exit:
    	DestroyProgressBar()
    	SetStatus(2, "",)
    	Return(ok)
EndMacro

Macro "SEMCOG PR Egress" (Args)//Called form PR Access
    	shared nOper
        shared UT

    	// Input Files
    	highway_db = Args.[Highway DB]
    	net_file = Args.[Network File]
        pregress_template = Args.[PnR Egress] //Use templates since loops use strings instead of indices

    	{node_lyr} = RunMacro("TCB Add DB Layers", highway_db)
    	ok = (node_lyr <> null)     if !ok then goto exit
    	db_lyr = highway_db + "|" + node_lyr

    	CreateProgressBar("Skimming", "TRUE")
    	Periods  = {"EA", "AM", "MD", "PM", "EV"}		//4 periods by JChen in July 2015
        pnrModes = {"LOC", "PRM", "MIX"}   // List of DRV transit modes

        //get node layer fields (to test for available PnR fields)
        {node_flds, } = GetFields(node_lyr, "All")

    	for i =1 to Periods.length do
    	   for j =1 to pnrModes.length do
	     period = Periods[i]
	     mode = pnrModes[j]

     	     SetStatus(2, "Computing " + " PR Egress",)
        	//===================================================
        	UpdateProgressBar("Skimming:  " + period + "   " + mode, r2i(i * 25))

            //Choose period and transit mode based on scnario manager template
            skim_mat = Substitute(pregress_template, "%PER_TRN%", period, )
            skim_mat = Substitute(skim_mat, "%TMODE%", mode, )

    		cent_qry = "Select * where Centroid <> null"

            //Use mode-specific park and ride only if field is present
            if ArrayPosition(node_flds, {mode+"_PNR"}, ) > 0 then do
                pnr_fld = mode+"_PNR"
            end else do
                pnr_fld = "PARK_RIDE"
            end
    		plot_qry = "Select * where " + pnr_fld + " > 0"

    		SkimOpts = {{"Input",   {{"Network",           net_file},
                             {"Origin Set",        {db_lyr, node_lyr,  "Parking Nodes", plot_qry}},
                             {"Destination Set",   {db_lyr, node_lyr, "centroid", cent_qry}},
                             {"Via Set",           {db_lyr, node_lyr}}}},
                {"Field",   {{"Nodes",             node_lyr + ".ID"}}},
                {"Global",  {{"Output Type",       "Matrix"}}}}


        	Opts = CopyArray(SkimOpts)
        	Opts.Field.Minimize = period + "_" + "HwyC"             // build path minimizing generalized cost
        	Opts.Field.[Skim Fields] = {{"Length",              "All"},     // skim on distance and time	cjl122008
        	                            {period + "_" + "HwyT", "All"}}
		Opts.Output.[Output Matrix].Label = period + " PR Egress"
        	Opts.Output.[Output Matrix].[File Name] = skim_mat

        	ok = RunMacro("TCB Run Procedure", nOper, "TCSPMAT", Opts)
        	if !ok then goto exit

        	nOper = nOper + 1
        	skim_m = RunMacro("TCB OpenMatrix", skim_mat,)
        	ok = (skim_m <> null)  if !ok then goto exit
        	SetMatrixCoreNames(skim_m, {"Cost", "Miles", "Drive Time"})		//cjl122008
		SetMatrixIndexName(skim_m, "Destination", "Parking")
    	end // end of pnr mode loop j
    	end // end of time period loop i

	skim_m = null
    	exit:
    	DestroyProgressBar()
    	SetStatus(2, "",)
    	Return(ok)
EndMacro

Macro "SEMCOG Transit Skims" (Args)
// Transit skims for all periods and modes
NextStep= "Define Files and Parameters"
SetStatus(1, NextStep, )
    shared nOper
    shared UT

    // Input Files
    db_file = Args.[Highway DB]
    rs_file = Args.[Route System]
    mode_file = Args.[Mode Table]

    tnw_files = UT.Expand(Args.[Transit Network])

    // Output Files
    tskim_files = UT.Expand(Args.[Transit Skims], {{"NestOrder", {"PER_TRN", "TMODE", "AMODE"}}})
    park_mat_files = UT.Expand(Args.[Parking Matrix], {{"NestOrder", {"PER_TRN", "TMODE", "AMODE"}}})

    //All modes transit skim (for auto ownership model and EJ reporting)
    allskm_file = Args.[Transit Skims]
    allskm_file = Substitute(allskm_file, "%AMODE%", "WLK", )
    allskm_file = Substitute(allskm_file, "%TMODE%", "All", )

    allskm_ea_file = Substitute(allskm_file, "%PER_TRN%", "EA", )
    allskm_am_file = Substitute(allskm_file, "%PER_TRN%", "AM", )
    allskm_md_file = Substitute(allskm_file, "%PER_TRN%", "MD", )
    allskm_pm_file = Substitute(allskm_file, "%PER_TRN%", "PM", )
    allskm_ev_file = Substitute(allskm_file, "%PER_TRN%", "EV", )
    allskm_files = {allskm_ea_file, allskm_am_file, allskm_md_file, allskm_pm_file, allskm_ev_file}  //must be in same order as Periods array.  only run for non-null values.
    allskm_file = null

    {node_lyr,} = RunMacro("TCB Add DB Layers", db_file)
    ok = (node_lyr <> null)     if !ok then goto exit
    db_node_lyr = db_file + "|" + node_lyr

    Periods  = {"EA", "AM", "MD", "PM", "EV"}	//Skim all periods, (PM and EV to check for transit paths in PA2OD)
    Modes =      {"LOC", "PRM", "MIX"}   // List of transit modes
    ivtt_modes = {"PMov", "Bus", "StCar", "Brt", "UrbRail", "ComRail", "DDOT", "SMART", "AAATA", "UMT", "BWAT", "LET"}
    AccessModes = {"WLK", "DRV", null, "DRVE", null} //Skim all three access/egress modes, including drive egress (DRVE) for use in PA2OD.  KnR is null so it will be skipped.
    //Process_AccessModes = {"WLK", "DRV", null, "DRVE"}//Only process skim walk, drive access.  Drive egress skims are only skimmed to check for a path.

    //Add an "All" mode for use in the auto availability model
    // - This is only skimmed for the WLK skim


//EndStep
NextStep= "Transit Skimming - Mode Table Use Check"
SetStatus(1, NextStep, )

    //Verify that the IS_mode fields are not duplicates.
    mode_vw = OpenTable("MODES", "FFB", {mode_file}, )
    SetView(mode_vw)
    SelectByQuery("T", "Several", "Select * Where Type = 'T'", )
    V = 0
    for m in Modes do
		if m = "MIX" then continue else V = V + nz(GetDataVector(mode_vw+"|T", "IS_"+m, ))
    end
    if VectorStatistic(V, "Max", ) >  1 then do
        ShowMessage("Error in MODE Table.  IS_* can only be True (1) for one column per transit mode.")
        Return(0)
    end

    dim SkimModes[Periods.length]
    dim IS_MODE[Periods.length]   //[period][TrnMode][SubMode][1=Name/2=IVTT_Fld]
	dim IS_MODE2[Periods.length]   //[period][TrnMode][SubMode][1=Name/2=IVTT_Fld]
    for period = 1 to Periods.length do
        period_s = Periods[period]

        //Define skimming by mode
        {TrnModes, Fld} = GetDataVectors(mode_vw+"|T", {"MODE_NAME", period_s+"_ImpFld"}, )
        for ii = 1 to TrnModes.length do
            SkimModes[period] = SkimModes[period] + {TrnModes[ii] + "." + Fld[ii]}
        end


        //Get {{MODE, IVTT}, ...} for each major mode
        for ii = 1 to Modes.length do
            SelectByQuery("M", "Several", "Select * Where Type = 'T' and IS_" + Modes[ii] + " = 1")
            {M, F} = GetDataVectors(mode_vw+"|M", {"MODE_NAME", period_s+"_ImpFld"}, )
            is_arr = TransposeArray({V2A(M), V2A(F)})
            IS_MODE[period] = IS_MODE[period] + {is_arr}
			SelectByQuery("M3", "Several", "Select * where USE_" + Modes[ii] + "=1", )
			skim_modes = v2a(GetDataVector(mode_vw+"|M3", "MODE_ID",))
        end

		//Get {{MODE, IVTT}, ...} for each linehaul (pmov, stcar, brt etc.) mode
        for ii = 1 to ivtt_modes.length do
            SelectByQuery("M2", "Several", "Select * Where Type = 'T' and IS_" + ivtt_modes[ii] + " = 1")
            {M2, F2} = GetDataVectors(mode_vw+"|M2", {"MODE_NAME", period_s+"_ImpFld"}, )
            is_arr2 = TransposeArray({V2A(M2), V2A(F2)})
            IS_MODE2[period] = IS_MODE2[period] + {is_arr2}
        end



    end //period

    CloseView(mode_vw)

    for period = 1 to Periods.length do
        for imode = 1 to Modes.length do
            for iacc = 1 to AccessModes.length do
                period_s = Periods[period]
                mode_t = Modes[imode]
                access = AccessModes[iacc]

                //Skip null access mode (to skip KnR, but based on setup arrays)
                if access = null then continue
//EndStep
NextStep= "Transit Skimming - " + JoinStrings({period_s, mode_t, access}, " ")
SetStatus(1, NextStep, )

                //Loop-specific files
                tnw_file = tnw_files[period]
                tskim_file  = tskim_files[period][imode][iacc]

                SkmOpts = null
                SkmOpts.Input.Database = db_file
                SkmOpts.Input.[Origin Set] = {db_node_lyr, node_lyr, "Centroids","Select * where Centroid <> null"}
                SkmOpts.Input.[Destination Set] = {db_node_lyr, node_lyr, "Centroids"}
                SkmOpts.Input.Network = tnw_file
                SkmOpts.Global.[Skim Var] = {"Generalized Cost",
                         "Fare",
                         "In-Vehicle Time",
                         "Initial Wait Time",
                         "Transfer Wait Time",
                         "Transfer Penalty Time",
                         "Transfer Walk Time",
                         "Access Walk Time",
                         "Egress Walk Time",
                         "Dwelling Time",
                         "Number of Transfers"} + SkimModes[period]
                //SkmOpts.Global.[Skim Modes] = skim_modes

                SkmOpts.Global.[OD Layer Type] = 2
                SkmOpts.Output.[Skim Matrix].Label = JoinStrings({period_s, access, mode_t, "Skims"}, " ")
                SkmOpts.Output.[Skim Matrix].Compression = 1
                SkmOpts.Output.[Skim Matrix].[File Name] = tskim_file

                // for drive access only
                if access = "DRV" then do
                  SkmOpts.Global.[Skim Var] = SkmOpts.Global.[Skim Var] + {"Access Drive Time", "Access Drive Distance"}
                  SkmOpts.Output.[Parking Matrix].Compression = 1
                  SkmOpts.Output.[Parking Matrix].[Label] = "Parking Access Nodes"
                  SkmOpts.Output.[Parking Matrix].[File Name] = park_mat_files[period][imode][iacc]
                end

                // for drive egress only
                if access = "DRVE" then do
                  SkmOpts.Global.[Skim Var] = SkmOpts.Global.[Skim Var] + {"Egress Drive Time", "Egress Drive Distance"}
				  //SkmOpts.Output.[Egre Park Matrix].Compression = 1
				  //SkmOpts.Output.[Egre Park Matrix].[Label] = "Parking Egress Nodes"
				  //SkmOpts.Output.[Egre Park Matrix].[File Name] = park_mat_files[period][imode][iacc]
                end

                //================================================
                if Modes[imode] = "MIX" then do
					ok = RunMacro("SEMCOG Set Transit Network", Args, period_s, mode_t, access, 5)  //the last argument is the 'global xfer weight'
					if !ok then goto exit
				end
				else do
					ok = RunMacro("SEMCOG Set Transit Network", Args, period_s, mode_t, access, 1)
					if !ok then goto exit
				end

                ok = RunMacro("TCB Run Procedure", "Transit Skim PF", SkmOpts, &Ret)
                if !ok then goto exit
                Ret = null

                //TCB transit skimming leaves a map open, so close all including the open map
                // Seems to be changed in TC8, no longer leaving a map open
                maps = GetMaps()
                if maps != null then do
                    maps = maps[1]
                    for m in maps do
                        SetMapSaveFlag(m, "False")
                    end
                end
                RunMacro("G30 File Close All")

            end // access mode Loop
        end // end of mode
    end // end of period loop

    for period = 1 to Periods.length do
        for imode = 1 to Modes.length do
            for iacc = 1 to AccessModes.length do

                if AccessModes[iacc] = null then continue

                period_s = Periods[period]
                mode_t = Modes[imode]
                access = AccessModes[iacc]

                tskim_file  = tskim_files[period][imode][iacc]

//EndStep
NextStep= "Read Skim into Memory - " + JoinStrings({period_s, mode_t, access}, " ")
SetStatus(1, NextStep, )

                mat_f = OpenMatrix(tskim_file, )
                cur_f = CreateMatrixCurrency(mat_f, "Generalized Cost", , , )
                t = SplitPath(tskim_file)
                Opts = null
                Opts.[File Name] = t[1]+t[2]+"__TEMP__"+t[3]+t[4]
                Opts.Label = mat_f.Label
                Opts.[Memory Only] = "True"

                mat = CopyMatrix(cur_f, Opts)

                mat_f = null
                cur_f = null

//EndStep
NextStep= "Consolidate IVTT - " + JoinStrings({period_s, mode_t, access}, " ")
SetStatus(1, NextStep, )

                //Consolidate all sub-modes into the primary modes.  This requires
                //  a second mode loop within the overall imode loop, designated here
                //  as jmode.

                if access <> null then do

                    for jmode = 1 to ivtt_modes.length do
                        ivtt_core = "IVTT_"+ivtt_modes[jmode]
                        AddMatrixCore(mat, ivtt_core)
                        curs = CreateMatrixCurrencies(mat, , , )

                        for sub_mode in IS_MODE2[period][jmode] do
                            sub_core = sub_mode[2] + " (" + sub_mode[1] + ")"
                            curs.(ivtt_core) := nz(curs.(ivtt_core)) + nz(curs.(sub_core))
                        end

                        curs = null
                    end

				    if Modes[imode] = "MIX" then do

				    	for jmode = 1 to (Modes.length - 1) do
				    		major_core = "IVTT_"+Modes[jmode]
				    		AddMatrixCore(mat, major_core)
				    		curs = CreateMatrixCurrencies(mat, , , )

				    		for sub_mode in IS_MODE[period][jmode] do
				    			sub_core = sub_mode[2] + " (" + sub_mode[1] + ")"
				    			curs.(major_core) := nz(curs.(major_core)) + nz(curs.(sub_core))
				    		end

				    		curs = null
				    	end
				    end

                    //Drop original IVTT Fields from matrix
                    //  Workaround: TC8 build 22165 seems to be setting the current core to
                    //              one of the IVTT by mode cores, so set the current core to
                    //              the first core in the matrix.
                    // ***** TEMP **** Condition to skip this for DRVE, remove later
					cores = GetMatrixCoreNames(mat)
					SetMatrixCore(mat, cores[1])
					for sm in SkimModes[period] do

						{m, f} = ParseString(sm, ".")
						core = f + " (" + m + ")"
						DropMatrixCore(mat, core)

					end //skim modes
                end
//EndStep
NextStep= "Update skim on disk - " + JoinStrings({period_s, mode_t, access}, " ")
SetStatus(1, NextStep, )

                cores = GetMatrixCoreNames(mat)
                curs = CreateMatrixCurrencies(mat, , , )
				// If both local and premium times are not there for a zone pair, remove it from the mix skims
                //for jmode = 1 to (Modes.length - 1) do
                    mode_l = Modes[1]
                	mode_p = Modes[2]
                	for c in cores do
                		if Modes[imode] = "MIX" then do
                			loc_core = "IVTT_"+mode_l
                			pre_core = "IVTT_"+mode_p
                			curs.(c) := if (nz(curs.(loc_core)) > 0) and (nz(curs.(pre_core)) > 0) then nz(curs.(c)) else null
                		end
                		else do
                			curs.(c) := nz(curs.(c))
                		end
                	end
                //end

                Opts = null
                Opts.[File Name] = tskim_file
                Opts.Label = mat.Label
                Opts.Compression = 1
                CopyMatrix(curs[1][2], Opts)

                curs = null
                mat = null

            end // access mode Loop (processed only)
        end // end of mode
    end // end of period loop (processed only)


    //Add ZoneID index to all skims
    for period = 1 to Periods.length do
        for imode = 1 to Modes.length do
            for iacc = 1 to AccessModes.length do

                period_s = Periods[period]
                mode_t = Modes[imode]
                access = AccessModes[iacc]

                tskim_file  = tskim_files[period][imode][iacc]

                //Skip null access mode (to skip KnR, but based on setup arrays)
                if access = null then continue

//EndStep
NextStep= "Zone to ID Index - " + JoinStrings({period_s, mode_t, access}, " ")
SetStatus(1, NextStep, )
                // add matrix index mapping node id to zone id for walk access matrices
                ok = RunMacro("Add Matrix Zone ID Index", tskim_file, Args)
                if !ok then goto exit


            end // access mode Loop
        end // end of mode
    end // end of period loop

//EndStep
NextStep= "All Modes Transit Skimming"
SetStatus(1, NextStep, )
    for _per = 1 to allskm_files.length do
        if allskm_files[_per] = null then continue
        per = Periods[_per]

//EndStep
NextStep= "All Modes Transit Skimming - " + per
SetStatus(1, NextStep, )

        //Loop-specific files
        tnw_file = tnw_files[_per] //1=AM
        allskm_file = allskm_files[_per]

        intrazonalfactor = Args.[IntrazonalFactor]
        intrazonalneighbors = r2i(Args.[IntrazonalNeighbors])

        SkmOpts = null
        SkmOpts.Input.Database = db_file
        SkmOpts.Input.[Origin Set] = {db_node_lyr, node_lyr, "Centroids","Select * where Centroid <> null"}
        SkmOpts.Input.[Destination Set] = {db_node_lyr, node_lyr, "Centroids"}
        SkmOpts.Input.Network = tnw_file
        SkmOpts.Global.[Skim Var] = {"Generalized Cost",
                         "Fare",
                         "In-Vehicle Time",
                         "Initial Wait Time",
                         "Transfer Wait Time",
                         "Transfer Penalty Time",
                         "Transfer Walk Time",
                         "Access Walk Time",
                         "Egress Walk Time",
                         "Dwelling Time",
                         "Number of Transfers"}

        SkmOpts.Global.[OD Layer Type] = 2
        SkmOpts.Output.[Skim Matrix].Label = per + " All Transit Walk Skim"
        SkmOpts.Output.[Skim Matrix].Compression = 1
        SkmOpts.Output.[Skim Matrix].[File Name] = allskm_file

        IntraOpts = {{"Input",    {{"Matrix Currency",   }}},
                     {"Global",   {{"Factor",            intrazonalfactor},
                                   {"Neighbors",         intrazonalneighbors},
                                   {"Operation",         1},
                                   {"Treat Missing",     1}}}}

        //================================================
        ok = RunMacro("SEMCOG Set Transit Network", Args, per, "All", "WLK")
        if !ok then goto exit

        ok = RunMacro("TCB Run Procedure", "Transit Skim PF", SkmOpts, &Ret)
        if !ok then goto exit
        Ret = null

        //TCB transit skimming leaves a map open, so close all including the open map
        // Seems to be changed in TC8, no longer leaving a map open
        maps = GetMaps()
        if maps != null then do
            maps = maps[1]
            for m in maps do
                SetMapSaveFlag(m, "False")
            end
        end
        RunMacro("G30 File Close All")

//EndStep
NextStep= "All Modes Skim Zone to ID Index - " + per
SetStatus(1, NextStep, )
        // add matrix index mapping node id to zone id for walk access matrices
        ok = RunMacro("Add Matrix Zone ID Index", allskm_file, Args)
        if !ok then goto exit

                mat = OpenMatrix(allskm_file, )
                curs = CreateMatrixCurrencies(mat, , , )
                cores = GetMatrixCoreNames(mat)

                for c in cores do
                	curs.(c) := nz(curs.(c))
                end

                omx_file = Substitute(allskm_file, ".mtx", ".omx", )
                copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 1}
                CopyMatrix(curs[1][2], copy_matrix_options)

    end //_per, for all transit skims

//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )

    exit:
    Return(ok)
//EndStep
EndMacro

Macro "SEMCOG Process Transit Skims" (Args)
NextStep= "Define Files and Parameters"
SetStatus(1, NextStep, )

    Shared UT

    //Intermediate Files
    tskim_files = UT.Expand(Args.[Transit Skims], {{"NestOrder", {"PER_TRN", "TMODE", "AMODE"}}})
    hskim_files = {Args.EAHwySkims, Args.AMHwySkims, Args.MDHwySkims, Args.PMHwySkims, Args.EVHwySkims}
	//hskim_files = UT.Expand(Args.HwySkims)

	Periods = {"EA", "AM", "MD", "PM", "EV"}
    Modes = {"LOC", "PRM", "MIX"}   // List of transit modes
    AccessModes = {"WLK", "DRV", null, "DRVE"}

    //Params
    ShortWalk = Args.ShortWalk
    LongWalk = Args.LongWalk
    ShortWait = Args.ShortWait

    for period = 1 to Periods.length do
		for imode = 1 to Modes.length do
	        for iacc = 1 to AccessModes.length do

				period_s = Periods[period]
                mode_t = Modes[imode]
                access = AccessModes[iacc]

                //Skip null access mode (to skip KnR, but based on setup arrays)
                if access = null then continue

//EndStep
NextStep= JoinStrings({period_s, mode_t, access}, " ") + " - Add Matrix Cores"
SetStatus(1, NextStep, )

                mat = OpenMatrix(tskim_files[period][imode][iacc], )

                curs = CreateMatrixCurrencies(mat, , , )
                cores = GetMatrixCoreNames(mat)

				for c in cores do
					curs.(c) := nz(curs.(c))
				end

                omx_file = Substitute(tskim_files[period][imode][iacc], ".mtx", ".omx", )
                copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 1}
                CopyMatrix(curs[1][2], copy_matrix_options)

            end // iacc

//EndStep
NextStep= JoinStrings({period_s, mode_t}, " ") + " - Create KnR Skims"
SetStatus(1, NextStep, )

            //KnR Skims are an exact copy of walk access skims, but with walk
            //  access time converted to drive access time and distance instead.
            //  walk access time is set to zero, or left null if no path.

            wlk_i = 1  //index of walk in the Access Mode list
            knr_i = 3   //index of knr in the Access Mode list

            wlk_file  = tskim_files[period][imode][wlk_i]
            knr_file  = tskim_files[period][imode][knr_i]

            // Copy walk to transit skim as knr to transit skim
            mc = CreateMatrixCurrency(OpenMatrix(wlk_file, ), "Generalized Cost", , , )

            Opts = null
            Opts.[File Name] = knr_file
            Opts.Label = JoinStrings({period_s, "KNR", mode_t, "Skims"}, " ")
            Opts.Compression = 1

            CopyMatrix(mc, Opts)
            mc = null

            //Convert walk access to drive access
            mat = OpenMatrix(knr_file, )

            AddMatrixCore(mat, "Access Drive Time")
            AddMatrixCore(mat, "Access Drive Distance")

            curs = CreateMatrixCurrencies(mat, , , )
			cores = GetMatrixCoreNames(mat)

            curs.[Access Drive Time] := curs.[Access Walk Time] * 0.2 // convert walk access time (3mph) to auto access time (15mph)
            curs.[Access Drive Distance] := curs.[Access Walk Time] * 0.05 //Convert walk access time (3 mph) to distance (miles)

            curs.[Access Walk Time] := if curs.[Access Walk Time] = null then null else 0 //Set access walk time to zero (leave null if no path)

            //************ Write OMX Skims **************
			for c in cores do
				curs.(c) := nz(curs.(c))
			end

            omx_file = Substitute(knr_file, ".mtx", ".omx", )
            copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 1}
            CopyMatrix(curs[1][2], copy_matrix_options)

            curs = null
            mat = null


			//*************************** KNR EGRESS *******************************


            wlk_i = 1  //index of walk in the Access Mode list
            knr_i = 3   //index of knr in the Access Mode list

            wlk_file  = tskim_files[period][imode][wlk_i]
            knr_file  = tskim_files[period][imode][knr_i]
			knre_file = Substitute(knr_file, "KNR", "KNRE", )

            // Copy walk to transit skim as knr to transit skim
            mc = CreateMatrixCurrency(OpenMatrix(wlk_file, ), "Generalized Cost", , , )

            Opts = null
            Opts.[File Name] = knre_file
            Opts.Label = JoinStrings({period_s, "KNRE", mode_t, "Skims"}, " ")
            Opts.Compression = 1

            CopyMatrix(mc, Opts)
            mc = null

            //Convert walk access to drive access
            mat = OpenMatrix(knr_file, )

            AddMatrixCore(mat, "Egress Drive Time")
            AddMatrixCore(mat, "Egress Drive Distance")

            curs = CreateMatrixCurrencies(mat, , , )
			cores = GetMatrixCoreNames(mat)

            curs.[Egress Drive Time] := curs.[Egress Walk Time] * 0.2 // convert walk access time (3mph) to auto access time (15mph)
            curs.[Egress Drive Distance] := curs.[Egress Walk Time] * 0.05 //Convert walk access time (3 mph) to distance (miles)

            curs.[Egress Walk Time] := if curs.[Egress Walk Time] = null then null else 0 //Set access walk time to zero (leave null if no path)

            //************ Write OMX Skims **************
			for c in cores do
				curs.(c) := nz(curs.(c))
			end

            omx_file = Substitute(knre_file, ".mtx", ".omx", )
            copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 1}
            CopyMatrix(curs[1][2], copy_matrix_options)

            curs = null
            mat = null

        end //imode
    end //period

//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )

    Return(1) //No TCB steps in this macro
//EndStep
EndMacro

//====== Commercial Vehicle ======//

Macro "SEMCOG CV Firm Synthesis" (Args)
	shared UT, Scen
	// Run Commercial Vehicle Model Firm Synthesis
    staticCVM = Args.[UseStaticCVMTrips]

    if staticCVM = 1 then do
        ok = 1
        return(ok)
    end
    
	// CVM batch file and application path argument to be passed to it
    bat_file = Args.[CVM Batch File]
	r_dir = Args.[R_DIR]
	
	// Create a file of input and output file information
    paths_file = Substitute(bat_file, ".bat", ".txt", )
	cv_paths = OpenFile(paths_file, "w")
	// R library directory, R freight zip location, and pandoc directory
	WriteLine(cv_paths, Args.[R_LIBRARY])
	WriteLine(cv_paths, Args.[PANDOC_DIR])
	// Scenario name, description, input and output directories, iteration, and CV component name
	WriteLine(cv_paths, Args.Info.Name)
	WriteLine(cv_paths, Args.Info.[Input Directory])
	WriteLine(cv_paths, Args.Info.[Output Directory])
	WriteLine(cv_paths, string(Scen.Feedback.iteration))
	WriteLine(cv_paths, "Firm Synthesis")
	// Path to the TAZ SE data for SEMCOG and the buffer and base year firms
	WriteLine(cv_paths, Args.[TAZ Land Use Data])
	WriteLine(cv_paths, Args.[Buffer TAZ Data])
	WriteLine(cv_paths, Args.[Base Year Firms])
    WriteLine(cv_paths, string(Args.[BaseScenario]))
	CloseFile(cv_paths)

        // Call the batch file with the component switch arguments set to run firm synthesis only
	status = null
	status=RunProgram(bat_file + " " + r_dir + " TRUE FALSE FALSE FALSE FALSE", {{"Maximize", "True"}})

	if status<>0 then do
		ShowMessage ("CVM Launch Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "SEMCOG CV Long Distance Model" (Args)
	shared UT, Scen
	// Run Commercial Vehicle Long Distance Model
    staticCVM = Args.[UseStaticCVMTrips]

    if staticCVM = 1 then do
        ok = 1
        return(ok)
    end

	// CVM batch file and application path argument to be passed to it
    bat_file = Args.[CVM Batch File]
	r_dir = Args.[R_DIR]
	
	// Create a file of input and output file information
    paths_file = Substitute(bat_file, ".bat", ".txt", )
	cv_paths = OpenFile(paths_file, "w")
	// R library directory, R freight zip location, and pandoc directory
	WriteLine(cv_paths, Args.[R_LIBRARY])
	WriteLine(cv_paths, Args.[PANDOC_DIR])
	// Scenario name, description, input and output directories, iteration, and CV component name
	WriteLine(cv_paths, Args.Info.Name)
	WriteLine(cv_paths, Args.Info.[Input Directory])
	WriteLine(cv_paths, Args.Info.[Output Directory])
	WriteLine(cv_paths, string(Scen.Feedback.iteration))
	WriteLine(cv_paths, "Long Distance")
	// Path to the facilities file, IEEI and EE Trucks, name of the distance skim core to use, and path to the midday skim
	WriteLine(cv_paths, Args.[Facilities Data])
	WriteLine(cv_paths, Args.[CVM IEEI Trucks])
	WriteLine(cv_paths, Args.[CVM EE Trucks])
    WriteLine(cv_paths, Args.[CVM Externals])
	WriteLine(cv_paths, "Miles")
	md_omx_file = Substitute(Args.MDHwySkims, ".mtx", ".omx", )
	WriteLine(cv_paths, md_omx_file)
    WriteLine(cv_paths, string(Args.[BaseScenario]))
	CloseFile(cv_paths)

        // Call the batch file with the component switch arguments set to run long distance only
	status = null
	status=RunProgram(bat_file + " " + r_dir + " FALSE TRUE FALSE FALSE FALSE", {{"Maximize", "True"}})

	if status<>0 then do
		ShowMessage ("CVM Launch Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "SEMCOG CV Touring Model" (Args)
	shared UT, Scen
	// Run Commercial Vehicle Touring Model
    staticCVM = Args.[UseStaticCVMTrips]

    if staticCVM = 1 then do
        ok = 1
        return(ok)
    end

	// CVM batch file and application path argument to be passed to it
    bat_file = Args.[CVM Batch File]
	r_dir = Args.[R_DIR]
	
	// Create a file of input and output file information
    paths_file = Substitute(bat_file, ".bat", ".txt", )
	cv_paths = OpenFile(paths_file, "w")
	// R library directory, R freight zip location, and pandoc directory
	WriteLine(cv_paths, Args.[R_LIBRARY])
	WriteLine(cv_paths, Args.[PANDOC_DIR])
	// Scenario name, description, input and output directories, iteration, and CV component name
	WriteLine(cv_paths, Args.Info.Name)
	WriteLine(cv_paths, Args.Info.[Input Directory])
	WriteLine(cv_paths, Args.Info.[Output Directory])
	WriteLine(cv_paths, string(Scen.Feedback.iteration))
	WriteLine(cv_paths, "CV Touring Model")
	// Names of the time, distance, and toll skim cores to use 
	//(if no toll, need to set BASE_TOLL_SKIM_AVAILABLE <- FALSE in CV model, any value here will then by ignored
	WriteLine(cv_paths, "Trav_Time")
	WriteLine(cv_paths, "Miles")
	WriteLine(cv_paths, "toll")
    WriteLine(cv_paths, Args.[CVM Externals])
	// Paths to the time period skims files (.OMX format)
	nt_omx_file = Substitute(Args.EAHwySkims, ".mtx", ".omx", )
	am_omx_file = Substitute(Args.AMHwySkims, ".mtx", ".omx", )
	md_omx_file = Substitute(Args.MDHwySkims, ".mtx", ".omx", )
	pm_omx_file = Substitute(Args.PMHwySkims, ".mtx", ".omx", )
	ev_omx_file = Substitute(Args.EVHwySkims, ".mtx", ".omx", )
	WriteLine(cv_paths, nt_omx_file)
	WriteLine(cv_paths, am_omx_file)
	WriteLine(cv_paths, md_omx_file)
	WriteLine(cv_paths, pm_omx_file)
	WriteLine(cv_paths, ev_omx_file)
	CloseFile(cv_paths)

        // Call the batch file with the component switch arguments set to run touring model only
	status = null
	status=RunProgram(bat_file + " " + r_dir + " FALSE FALSE TRUE FALSE FALSE", {{"Maximize", "True"}})

	if status<>0 then do
		ShowMessage ("CVM Launch Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "SEMCOG CV Trip Tables" (Args)
	shared UT, Scen
	// Run Commercial Vehicle Model Trip Tables
    staticCVM = Args.[UseStaticCVMTrips]
    output_dir = Args.Info.[Output Directory]

    if staticCVM = 1 then do
        Periods  = {"AM", "MD", "PM", "EV", "EA", "DY"}
        Periods2 = {"AM", "MD", "PM", "EV", "EA", "Daily"}
        Modes = {"Light Truck", "Medium Truck", "Heavy Truck"}

        // convert omx files into mtx and read them back in: gisdk is buggy with doing matrix operation on omx files
        dim tt_tables[Periods.length]
        for period=1 to Periods.length do
            input_name = Substitute(Args.[OD Trip Tables], "%PER_HWY%", Periods[period], )
            output_name = Substitute(input_name, ".omx", ".mtx", )
            tt = CreateMatrixCurrency(OpenMatrix(input_name, ),,,,)
            CopyMatrix(tt, {{"File Name", output_name}, })
            tt_tables[period] = OpenMatrix(output_name, )
        end
        // delete exising cores
        for period=1 to Periods.length do
	    cores = GetMatrixCoreNames(tt_tables[period])
            for mode = 1 to Modes.length do
		for c in cores do
 			if Modes[mode] = c then DropMatrixCore(tt_tables[period], Modes[mode])
		end
            end
        end
        //add cores 
        for period=1 to Periods.length do
            for mode = 1 to Modes.length do
                AddMatrixCore(tt_tables[period], Modes[mode])
            end
        end
        //create mat currencies
        dim tt_tables_curr[Periods.length]
        for period=1 to Periods.length do
            tt_tables_curr[period] = CreateMatrixCurrencies(tt_tables[period], "All", , )
        end
        //convert the cv trip tables to mtx and read them back in
        tt = CreateMatrixCurrency(OpenMatrix(Args.[CVM Static Trip Table],),,,, )
        CopyMatrix(tt, {{"File Name", Substitute(Args.[CVM Static Trip Table], ".omx", ".mtx", )}, })
        cv_mat = OpenMatrix(Substitute(Args.[CVM Static Trip Table], ".omx", ".mtx", ), )
        cv_tt = CreateMatrixCurrencies(cv_mat, , , )

        // add tables from cv trip table (tt) to tt_tables  
        for period=1 to Periods2.length do
            for mode = 1 to Modes.length do
                tt_tables_curr[period].(Modes[mode]) := cv_tt.(Periods2[period] + " " + Modes[mode])
            end
        end
        //write out the new trip tables
        for period=1 to Periods.length do
            CopyMatrix(tt_tables_curr[period].SHARED2, {{"File Name", Substitute(Args.[OD Trip Tables], "%PER_HWY%", Periods[period], )}, {"OMX", "TRUE"} })
        end

        tt = Null
        cv_mat = Null
        cv_tt = Null


        ok = 1
        return(ok)
    end
	
	// CVM batch file and application path argument to be passed to it
    bat_file = Args.[CVM Batch File]
	r_dir = Args.[R_DIR]
	
	// Create a file of input and output file information
    paths_file = Substitute(bat_file, ".bat", ".txt", )
	cv_paths = OpenFile(paths_file, "w")
	// R library directory, R freight zip location, and pandoc directory
	WriteLine(cv_paths, Args.[R_LIBRARY])
	WriteLine(cv_paths, Args.[PANDOC_DIR])
	// Scenario name, description, input and output directories, iteration, and CV component name
	WriteLine(cv_paths, Args.Info.Name)
	WriteLine(cv_paths, Args.Info.[Input Directory])
	WriteLine(cv_paths, Args.Info.[Output Directory])
	WriteLine(cv_paths, string(Scen.Feedback.iteration))
	WriteLine(cv_paths, "CV Trip Tables")
	// Path to the OD trip tables
	WriteLine(cv_paths, Args.[OD Trip Tables])
	CloseFile(cv_paths)

    // Call the batch file with the component switch arguments set to run CV trip tables only
	status = null
	status=RunProgram(bat_file + " " + r_dir + " FALSE FALSE FALSE TRUE FALSE", {{"Maximize", "True"}})

	if status<>0 then do
		ShowMessage ("CVM Launch Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "SEMCOG CV Dashboard" (Args)
	shared UT, Scen
	// Create Commercial Vehicle Model Dashboard
    staticCVM = Args.[UseStaticCVMTrips]

    if staticCVM = 1 then do
        ok = 1
        return(ok)
    end
	
	// CVM batch file and application path argument to be passed to it
    bat_file = Args.[CVM Batch File]
	r_dir = Args.[R_DIR]
	
	// Create a file of input and output file information
    paths_file = Substitute(bat_file, ".bat", ".txt", )
	cv_paths = OpenFile(paths_file, "w")
	// R library directory, R freight zip location, and pandoc directory
	WriteLine(cv_paths, Args.[R_LIBRARY])
	WriteLine(cv_paths, Args.[PANDOC_DIR])
	// Scenario name, description, input and output directories, iteration, and CV component name
	WriteLine(cv_paths, Args.Info.Name)
	WriteLine(cv_paths, Args.Info.[Input Directory])
	WriteLine(cv_paths, Args.Info.[Output Directory])
	WriteLine(cv_paths, string(Scen.Feedback.iteration))
	WriteLine(cv_paths, "CV Dashboard")
    // Whether to write the spreadsheet summary (FALSE), path to assignment outputs
	WriteLine(cv_paths, "FALSE")
	WriteLine(cv_paths, Args.[Highway Flows])
	CloseFile(cv_paths)

        // Call the batch file with the component switch arguments set to run CV dashboard only
	status = null
	status=RunProgram(bat_file + " " + r_dir + " FALSE FALSE FALSE FALSE TRUE", {{"Maximize", "True"}})

	if status<>0 then do
		ShowMessage ("CVM Launch Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

//====== ActivitySim ======//

Macro "Synthetic Population Processing"

	shared reindex_synpop
	reindex_synpop = 1

	Return(1)

endMacro

Macro "ActivitySim Input Checker" (Args)
	shared UT, Scen, reindex_synpop
	// Run ActivitySim Input Checker

    Output_dir = Args.Info.[Output Directory]
    
    bat_file0 = Args.[Process landuse]
    t = SplitPath(bat_file0)
    bat_filename0 = t[3] + t[4]
    bat_filename = "run_semcog_abm_inputchecker.bat"
    bat_file = Substitute(bat_file0, bat_filename0, bat_filename, )
    anaconda_dir = Args.[Anaconda_DIR]
    env_dir = Args.[ENV_DIR]
    env_name = Args.[PYTHON_ENV_NAME]
    hhfile_dir = Args.[Synthetic Households File]
    personfile_dir = Args.[Synthetic Persons File]
    landuse_dir = Args.[Land Use Data]
    merged_landuse_data_dir = Args.[Merged Land Use Data]

    t = SplitPath(hhfile_dir)
    hhfile_name = t[3] + t[4]
    input_dir = t[1] + t[2]
    t = SplitPath(personfile_dir)
    personfile_name = t[3] + t[4]
    t = SplitPath(land_use)
    landuse_name = t[3] + t[4]

	status = null
	status=RunProgram(bat_file + " " + input_dir + " " + anaconda_dir + " " + env_dir + " " + hhfile_name + " " + personfile_name + " " + landuse_dir + " " + Output_dir + " " + env_name, {{"Maximize", "True"}})

	if status<>0 then do
		ShowMessage ("ActivitySim Input Checker failed!")
	end
	else do
		ShowMessage ("ActivitySim Input Checker Completed! Check the log file for any errors ...")
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "ActivitySim Preprocessing" (Args)
	shared UT, Scen, reindex_synpop
	// Run ActivitySim

    Output_dir = Args.Info.[Output Directory]
    
	bat_file = Args.[ActivitySim Preprocessing Batch File]
    anaconda_dir = Args.[Anaconda_DIR]
    env_dir = Args.[ENV_DIR]
    env_name = Args.[PYTHON_ENV_NAME]
    hhfile_dir = Args.[Synthetic Households File]
    personfile_dir = Args.[Synthetic Persons File]
    other_zonal_data_dir = Args.[Other Zonal Data]
	iteration = Scen.Feedback.iteration

    merged_landuse_data_dir = Args.[Merged Land Use Data]

	if reindex_synpop <> 1 then reindex = 0 else reindex = 1

    t = SplitPath(hhfile_dir)
    hhfile_name = t[3] + t[4]
    input_dir = t[1] + t[2]
    t = SplitPath(personfile_dir)
    personfile_name = t[3] + t[4]
    t = SplitPath(merged_landuse_data_dir)
    landuse_name = t[3] + t[4]

	status = null
	status=RunProgram(bat_file + " " + String(iteration) + " " + String(reindex) + " " + input_dir + " " + anaconda_dir + " " + env_dir + " " + hhfile_name + " " + personfile_name + " " + merged_landuse_data_dir + " " + Output_dir + " " + env_name, {{"Maximize", "True"}})


	if status<>0 then do
		ShowMessage ("ActivitySim Launch Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "ActivitySim" (Args)
	shared UT, Scen, reindex_synpop

    Input_dir = Args.Info.[Input Directory]
    Output_dir = Args.Info.[Output Directory]

	bat_file = Args.[ActivitySim Batch File]
    anaconda_dir = Args.[Anaconda_DIR]
    env_dir = Args.[ENV_DIR]
    env_name = Args.[PYTHON_ENV_NAME]
    hhfile_dir = Args.[Synthetic Households File]
    personfile_dir = Args.[Synthetic Persons File]
    merged_landuse_data_dir = Args.[Merged Land Use Data]
	iteration = Scen.Feedback.iteration

    t_hh = SplitPath(hhfile_dir)
    hhfile_name = t_hh[3] + t_hh[4]
    hh_dir = t_hh[1] + t_hh[2]
    t_per = SplitPath(personfile_dir)
    personfile_name = t_per[3] + t_per[4]
    per_dir = t_per[1] + t_per[2]
    t_lu = SplitPath(merged_landuse_data_dir)
    landuse_name = t_lu[3] + t_lu[4]
    lu_dir = t_lu[1] + t_lu[2]

    //check to see if hh, per, and lu are in the same directory. if not copy them into the WorkingFiles directory since activitysim expects them to.
    if iteration = 1 then if (hh_dir = per_dir) & (per_dir = lu_dir) then Input_dir = hh_dir else do
        Input_dir = Output_dir + "WorkingFiles/input_to_activitysim/"
        CopyFile(personfile_dir, Input_dir + personfile_name)
        CopyFile(merged_landuse_data_dir, Input_dir + landuse_name)
        CopyFile(hhfile_dir, Input_dir + hhfile_name)
    end

    if iteration > 1 then if (hh_dir = per_dir) & (per_dir = lu_dir) then Input_dir = hh_dir else Input_dir = Output_dir + "WorkingFiles/input_to_activitysim/"
        

	status = null
	status=RunProgram(bat_file + " " + String(iteration) + " " + env_name + " " + Input_dir + " " + anaconda_dir + " " + env_dir + " " + hhfile_name + " " + personfile_name + " " + landuse_name + " " + Output_dir, {{"Maximize", "True"}})


	if status<>0 then do
		ShowMessage ("ActivitySim Launch Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "ActivitySim Postprocessing" (Args)
	shared UT, Scen, reindex_synpop
	
    Input_dir = Args.Info.[Input Directory]
    Output_dir = Args.Info.[Output Directory]

	bat_file = Args.[ActivitySim Postprocessing Batch File]
    anaconda_dir = Args.[Anaconda_DIR]
    env_dir = Args.[ENV_DIR]
    env_name = Args.[PYTHON_ENV_NAME]
    EE_file = Args.[Person EE file]
	scen_name = Args.Info.Name
	iteration = Scen.Feedback.iteration

	status = null
	status=RunProgram(bat_file + " " + String(iteration) + " " + env_name + " " + Input_dir + " " + anaconda_dir + " " + env_dir + " " + EE_file + " " + Output_dir, {{"Maximize", "True"}})


	if status<>0 then do
		ShowMessage ("ActivitySim Launch Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "Visualizer" (Args)

	shared UT, Scen
	// Run Visualizer
	bat_file = Args.[ActivitySim Visualizer Batch File]
	Input_dir = Args.Info.[Input Directory]
    base_is_survey = Args.[BASE_IS_SURVEY]
    base_scen_dir = Args.[BASE_SCEN_DIR]

    anaconda_dir = Args.[Anaconda_DIR]
    env_dir = Args.[ENV_DIR]
    env_name = Args.[PYTHON_ENV_NAME]
    Output_dir = Args.Info.[Output Directory]
    ee_file = Args.[Person EE file]
	
	r_dir = Args.[R_DIR]
	r_library = Args.[R_LIBRARY]
	pandoc_dir = Args.[PANDOC_DIR]

    status = null
	status=RunProgram(bat_file + " " + Input_dir + " " + string(base_is_survey) + " " + anaconda_dir + " " + env_dir + " " + Output_dir + " " + ee_file + " " +  env_name + " " + base_scen_dir + " " + r_dir + " " + r_library + " " + pandoc_dir, {{"Maximize", "True"}})

    if status<>0 then do
		ShowMessage ("ActivitySim Visualizer Launch Failed!")
    end

	Return(1)

endMacro

//====== Assignment ======//       (highway and transit assignments)

// EA Highway Assignment
Macro "SEMCOG EA Highway Assignment" (Args)
    ok = RunMacro("Highway Assignment", Args, "EA")
    SetStatus(2, "",)
    return(ok)
EndMacro

// AM Highway Assignment
Macro "SEMCOG AM Highway Assignment" (Args)
    ok = RunMacro("Highway Assignment", Args, "AM")
    SetStatus(2, "",)
    return(ok)
EndMacro

// MD Highway Assignment
Macro "SEMCOG MD Highway Assignment" (Args)
    ok = RunMacro("Highway Assignment", Args, "MD")
    SetStatus(2, "",)
    return(ok)
EndMacro

// PM Highway Assignment
Macro "SEMCOG PM Highway Assignment" (Args)
    ok = RunMacro("Highway Assignment", Args, "PM")
    SetStatus(2, "",)
    return(ok)
EndMacro

// EV Highway Assignment
Macro "SEMCOG EV Highway Assignment" (Args)
    ok = RunMacro("Highway Assignment", Args, "EV")
    SetStatus(2, "",)
    return(ok)
EndMacro


// Highway Assignment
Macro "Highway Assignment" (Args, period)       // period:AM|MD|PM|EV/EA
    shared  nOper, TransCADVersion
    shared Scen

        // Input Files
    db_file = Args.[Highway DB]
    net_file = Args.[Network File]
    od_mat = Substitute(Args.[OD Trip Tables], "%PER_HWY%", period, )
	od_mat = Substitute(od_mat, ".mtx", ".OMX", )
    qry_file = Args.[Crit_Query]
        // Output Files
    flow_tb = Substitute(Args.[Highway Flows], "%PER_HWY%", period, )
    iter_tb = Substitute(Args.[Iteration Log], "%PER_HWY%", period, )
        // Parameters
    iterations  = Args.("Assign_" + period + "_Iter")
    convergence = Args.("Assign_" + period + "_Conv")

    //Determine if select link/zone analysis should be run
    // - file must be present, only run on final/converged feedback iteration
    run_CriticalLinkAnalysis = null
    if !Scen.Feedback.run or (Scen.Feedback.iteration = Scen.Feedback.iters) or Scen.Feedback.Converged then do
        if GetFileInfo(qry_file) != null then do
            run_CriticalLinkAnalysis = true
        end
    end


	// changed to define the exclusive links for HOV, SOV/Light Trucks, or Medium/Heavy Trucks by JChen in May 2015
    mode_tb = Args.[Mode Table]
    {, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
    mode_vw = RunMacro("TCB OpenTable",,, {mode_tb})
    ok = (link_lyr <> null && mode_vw <> null)
    jvw = JoinViews("jvw", link_lyr+".mode_id", mode_vw+".mode_id",)   // join mode table to link layer
    vw_set = jvw + "|"
    db_link_lyr = db_file + "|" + link_lyr

    {HOV2_links_qry, HOV3_links_qry, SOV_LT_links_qry, MT_HT_links_qry} = RunMacro("GetExclusionQueries", link_lyr, period)

    SOV_LT_links_set =  {db_link_lyr, link_lyr, "SOV_LT_set", SOV_LT_links_qry}
    HOV2_links_set =  {db_link_lyr, link_lyr, "HOV2_set", HOV2_links_qry}
    HOV3_links_set =  {db_link_lyr, link_lyr, "HOV3_set", HOV3_links_qry}
    MT_HT_links_set =  {db_link_lyr, link_lyr, "MT_HT_set", MT_HT_links_qry}

	//@ k = Args.[GC Constant]              // K value in link generalized cost function
    k = 0
    vod = Args.[Distance weight]        // value of distance (dollars per mile)
    vot = Args.[Time weight]            // value of distance (dollars per minute)
       // Lists
    sov_array = Args.[sov_array]
    hov2_array = Args.[hov2_array]
    hov3_array = Args.[hov3_array]
    ltk_array = Args.[ltk_array]
    mtk_array = Args.[mtk_array]
    htk_array = Args.[htk_array]

    SetStatus(2, "Running " + period + " Highway Assignment",)
    //=============================================================

	ret_value = RunMacro("Add Matrix Node ID Index", od_mat, Args)
    if !ret_value then goto exit

    Opts = null
    Opts.Input.Database = db_file
    Opts.Input.Network  = net_file
    Opts.Input.[OD Matrix Currency] = {od_mat, "DRIVEALONE", "NodeID", "NodeID"}

	// changed to exclude the link sets for each vehicle classes by J. Chen in October of 2013 and April of 2014
    setlayer(link_lyr)
    m = SelectByQuery("Selection","Several",SOV_LT_links_qry,)
    n2 = SelectByQuery("Selection","Several",HOV2_links_qry,)
    n3 = SelectByQuery("Selection","Several",HOV3_links_qry,)
    l = SelectByQuery("Selection","Several",MT_HT_links_qry,)
    if m = 0 then SOV_LT_links_set = ""
    if n2 = 0 then HOV2_links_set = ""
    if n3 = 0 then HOV3_links_set = ""
    if l = 0 then MT_HT_links_set = ""
    Opts.Input.[Exclusion Link Sets] = {SOV_LT_links_set, MT_HT_links_set, SOV_LT_links_set, MT_HT_links_set, HOV2_links_set, HOV3_links_set} //DRIVEALONE, HEAVY, LIGHT, MEDIUM, SHARED2, SHARED3 - IN APLHABETICAL ORDER
    Opts.Field.[Vehicle Classes] = {1,2,3,4,5,6}	// revised by SA in Jan. 2015
    Opts.Field.[Fixed Toll Fields] = { , , , , , }


//    Opts.Global.[Load Method] = 5           // UE
// changed to Caliper's bi-conjugate taffic assignment method by J. Chen on Mar. 20, 2013
    Opts.Global.[Load Method] = "NCFW"
    Opts.Global.[N Conjugate] = 2

//check if select link analysis should be included by J. Chen in October, 2013
    if run_CriticalLinkAnalysis then do
		crit_file = Substitute(Args.SelectMatrix, "%PER_HWY%", period, )
		Opts.Global.[Critical Query File] = qry_file
		Opts.Output.[Critical Matrix].Label = "Critical Matrix"
		Opts.Output.[Critical Matrix].Compression = 1
		Opts.Output.[Critical Matrix].[File Name] = crit_file
	end

    Opts.Global.[Loading Multiplier] = 1
    Opts.Global.[Alpha Value] = 0.15
    Opts.Global.[Beta Value] = 4
    Opts.Global.Convergence  = convergence
    Opts.Global.Iterations = r2i(iterations)
    Opts.Global.[Number of Classes] =  6
    Opts.Global.[Class PCEs] = {sov_array[1], htk_array[1], ltk_array[1], mtk_array[1], hov2_array[1], hov3_array[1]}
    Opts.Global.[Class VOIs] = {sov_array[2], htk_array[2], ltk_array[2], mtk_array[2], hov2_array[2], hov3_array[2]}
    cap_fld  = period + "Cap"
    Opts.Global.[Cost Function File] = "gc_vdf.vdf"
    if TransCADVersion < 5.0 then do
        Opts.Field.[VDF Fld Names] = {"FF_Time", cap_fld, "Alpha", "Beta", "None", "None", "None", "Length", "Speed", "None"}
        Opts.Global.[VDF Defaults] = {         ,        ,    0.15,      4,      k,    vod,    vot,         ,        ,      0}
        end
    else do // if transCAD 5.0 or above, remove "Speed"
        Opts.Field.[VDF Fld Names] = {"FF_Time", cap_fld, "Alpha", "Beta", "None", "None", "None", "Length", "None"}
        Opts.Global.[VDF Defaults] = {         ,        ,    0.15,      4,      k,    vod,    vot,         ,      0}
    end

    Opts.Flag.[Do Share Report] = 1
    Opts.Output.[Flow Table] = flow_tb
    Opts.Output.[Iteration Log] = iter_tb  //Save an iteration log

    ok = RunMacro("TCB Run Procedure", nOper, "MMA", Opts, &Ret)
    if !ok then goto exit

//if select link analysis is included,  add matrix index -- Zone ID by J. Chen in October, 2013
	if run_CriticalLinkAnalysis = 1 then do
		ok = RunMacro("Add Matrix Zone ID Index", crit_file, Args)
		if !ok then goto exit
	end


    period_idx = ArrayPosition({"EA", "AM", "MD", "PM", "EV"}, {period},)

     exit:
     closeview(jvw)
     SetStatus(2, "",)
     Return(ok)
EndMacro

Macro "GetExclusionQueries" (link_lyr, period)
    //Exclusion sets for assignment AND skimming.
    // if link_lyr = null, assume no join or duplicate views.
    // if link_lyr != nll, then add link_lyr+"." before MODE_ID

    if link_lyr = null then do
        mode_fld = "MODE_ID"
		nfc_fld  = "NFC"
    end else do
        mode_fld = link_lyr+".MODE_ID"
		nfc_fld  = link_lyr+".NFC"
    end


    If period = "AM" then do
	    HOV2_links_qry = "Select * where (" + mode_fld + " =6 or  " + mode_fld + " =8)" //these links are excluded for HOVs
	    SOV_LT_links_qry = "Select * where (" + mode_fld + " = 4 or " + mode_fld + " = 5 or " + mode_fld + " = 6 or "  + mode_fld + " =8 )" 	//these links are excluded for SOV and Light Trucks
	    MT_HT_links_qry = "Select * where (" + mode_fld + " >= 4 and " + mode_fld + " < 10)" 	//these links are excluded for Medium and Heavy Trucks
	end else if period = "PM" then do
	    HOV2_links_qry = "Select * where (" + mode_fld + " =5 or  " + mode_fld + " =7)" //these links are excluded for HOVs
	    SOV_LT_links_qry = "Select * where (" + mode_fld + " = 4 or "  + mode_fld + " = 5 or " + mode_fld + " = 6 or "  + mode_fld + " = 7 )" 	//these links are excluded for SOV and Light Trucks
	    MT_HT_links_qry = "Select * where (" + mode_fld + " >= 4 and " + mode_fld + " < 10)" 	//these links are excluded for Medium and Heavy Trucks
	end else do
	    HOV2_links_qry = "Select * where (" + mode_fld + " > 4 and  " + mode_fld + " < 10)" //these links are excluded for HOVs
	    SOV_LT_links_qry = "Select * where (" + mode_fld + " > 4 and "  + mode_fld + " < 10)" 	//these links are excluded for SOV and Light Trucks
	    MT_HT_links_qry = "Select * where (" + mode_fld + " > 4 and " + mode_fld + " < 10)" 	//these links are excluded for Medium and Heavy Trucks
	end

	nonMotLinks_qry = "Select * where (" + nfc_fld + " = 1 or  " + nfc_fld + " = 2 or  " + nfc_fld + " = 81 or  " + nfc_fld + " = 82 or  " + nfc_fld + " = 83)" //these links are excluded for non-motorized

    HOV3_links_qry = HOV2_links_qry

    //Currently assumes the same exclusion sets for HOV2 and HOV3
    Return({HOV2_links_qry, HOV3_links_qry, SOV_LT_links_qry, MT_HT_links_qry, nonMotLinks_qry})
EndMacro


// ****************************************************************************************************************
// Speed Feedback Macro
//
// This macro computes speeds to feed back to distribution and mode choice.
//
// This macro should NOT be run on the final feedback iteration.  It does the following:
//  - Computes MSA flows and resulting speeds
//  - Places the resulting MSA flows on the network
//  - *Moves* the assignment from this feedback iteration to the subfolder "Feedbac" and adds "FBn"
//    to the filename
//
Macro "SEMCOG Feedback" (Args)


NextStep= "Define Files and Data"
SetStatus(1, NextStep, )

    shared Scen //For feedback settings
    shared fb_AB_MSAFlow, fb_BA_MSAFlow

	// Input Files
	dbd_file = Args.[Highway DB]
	net_file = Args.[Network File]

    //Parameters
	vod = Args.[Distance weight]        // value of distance (dollars per mile)
	vot = Args.[Time weight]            // value of distance (dollars per minute)
    per2_names = {"AM", "MD", "PM"} // Only feed back AM and PM since other periods are not assigned in intermediate loops //Args.HwyPeriods

    //Just load feedback flow filenames
    flow_files = null
    iter_files = null
    for ii = 1 to per2_names.length do
        flow_files = flow_files + {Substitute(Args.[Highway Flows], "%PER_HWY%", per2_names[ii], )}
        iter_files = iter_files + {Substitute(Args.[Iteration Log], "%PER_HWY%", per2_names[ii], )}
    end

    fb_method = 1 //1=MSA w with weight 0.5; 2=MSA; 3=naive

    //Immediately exit if running final full loop, or if not running feedback
    //  this allows reproduction of final feedback results in later runs
    if !Scen.Feedback.run or (Scen.Feedback.iteration = Scen.Feedback.iters) or Scen.Feedback.Converged then do
        Return(1)
    end

//EndStep
NextStep= "Create Feedback Directory"
SetStatus(1, NextStep, )
    //always define fbasn_dir
    t = SplitPath(flow_files[1])
    fbasn_dir = t[1] + t[2] + "FeedbackAssign\\"

    //Only clear/create if on the first iteration
	if Scen.Feedback.iteration = 1 then do

        //creating the directory
        tmp = left(fbasn_dir, len(fbasn_dir)  -1)  //w/o trailing backslash
        exist = GetDirectoryInfo(tmp+"*", "Directory") //does directory exist
        files = GetDirectoryInfo(fbasn_dir+"*", "File") //does directory exist and contain files
        //Create directory if non-existent
        if exist = null then do
            CreateDirectory(fbasn_dir)
        end
        //Clear files if they exist
        if files != null then do
            for i = 1 to files.length do
                DeleteFile(fbasn_dir + files[i][1])
            end
        end

        //arrays to hold flows
        //These are shared variables and are only initialized on the first iteration
        dim fb_AB_MSAFlow[flow_files.length]
        dim fb_BA_MSAFlow[flow_files.length]

	end


	//Compute new speeds for each period
	for _per = 1 to per2_names.length do
        per2 = per2_names[_per]
//EndStep
NextStep= "Copy Flow Data (Period "+per2+")"
SetStatus(1, NextStep, )
		t = SplitPath(flow_files[_per])
        prev_file = fbasn_dir + t[3] + "_I" + string(Scen.Feedback.iteration) + t[4]
		CopyTableFiles(, "FFB", flow_files[_per], , prev_file, )

        //Also copy iteration logs
		t = SplitPath(iter_files[_per])
        prev_file = fbasn_dir + t[3] + "_I" + string(Scen.Feedback.iteration) + t[4]
		CopyTableFiles(, "FFB", iter_files[_per], , prev_file, )
//EndStep
NextStep= "Load Flow Data (Period " + per2 + ")"
SetStatus(1, NextStep, )

		//load dbd network
	    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", dbd_file,,)

		//Join flow data to the line layer
		flow_vw = OpenTable("PeriodFlows", "FFB", {flow_files[_per],})
		join_vw = JoinViews("JoinFlows", link_lyr+".ID", flow_vw+".ID1", )

		//Select only assigned links
		SetView(join_vw)
		SelectByQuery("Traffic", "Several", "Select * Where ID1 > 0", )

		//Get current flow, freeflow speed, capacity, alpha, and beta
		AB_Flow = GetDataVector(join_vw+"|Traffic", "AB_Flow", )
		BA_Flow = GetDataVector(join_vw+"|Traffic", "BA_Flow", )
		Length  = GetDataVector(join_vw+"|Traffic", "Length", )
		AB_FFTime = GetDataVector(join_vw+"|Traffic", link_lyr+".AB_TIME", )
		BA_FFTime = GetDataVector(join_vw+"|Traffic", link_lyr+".BA_TIME", )
        AB_Cap  = GetDataVector(join_vw+"|Traffic", "AB_"+per2+"Cap", )
        BA_Cap  = GetDataVector(join_vw+"|Traffic", "BA_"+per2+"Cap", )
		ALPHA   = GetDataVector(join_vw+"|Traffic", "Alpha", )
		BETA    = GetDataVector(join_vw+"|Traffic", "Beta", )

        Length = Max(Length, 0.0001) //Prevent issues with very short links

        //Always use the naive method for the first iteration
		if Scen.Feedback.iteration = 1 then do
			fb_AB_MSAFlow[_per] = AB_Flow
			fb_BA_MSAFlow[_per] = BA_Flow
		end
		else do

			//*** OPTION ***
			//*** The equations below use the constant weight method.
			if fb_method = 1 then do
				wt = 0.5
				fb_AB_MSAFlow[_per] = fb_AB_MSAFlow[_per] + (AB_Flow - fb_AB_MSAFlow[_per]) * wt
				fb_BA_MSAFlow[_per] = fb_BA_MSAFlow[_per] + (BA_Flow - fb_BA_MSAFlow[_per]) * wt
				method_text = "Constant Weight"
			end

			//*** OPTION ***
			//*** The equations below use the method of successive averages.
			if fb_method = 2 then do
				fb_AB_MSAFlow[_per] = fb_AB_MSAFlow[_per] + (AB_Flow - fb_AB_MSAFlow[_per])/Scen.Feedback.iteration
				fb_BA_MSAFlow[_per] = fb_BA_MSAFlow[_per] + (BA_Flow - fb_BA_MSAFlow[_per])/Scen.Feedback.iteration
				method_text = "MSA"
			end

			//*** OPTION ***
			//*** The equations below use the naive feedback method.
			else if fb_method = 3 then do
				fb_AB_MSAFlow[_per] = AB_Flow
				fb_BA_MSAFlow[_per] = BA_Flow
				method_text = "Naive"
			end
		end

		//Compute the updated travel times
		AB_Time = AB_FFTime * (1 + ALPHA*pow(fb_AB_MSAFlow[_per] / AB_Cap, BETA))
		BA_Time = BA_FFTime * (1 + ALPHA*pow(fb_BA_MSAFlow[_per] / BA_Cap, BETA))

		//Compute updated speeds to save on the network
		//Use a minimum speed of 5 miles per hour
		AB_Speed = max(5, Length * 60 / AB_Time)
		BA_Speed = max(5, Length * 60 / BA_Time)

        //Re-calculate time after minimum speed
        AB_Time = Length * 60 / AB_Speed
        BA_Time = Length * 60 / BA_Speed

        //Generalized Cost for shortest path minimization
        AB_Cost = vod * Length + vot * AB_Time
        BA_Cost = vod * Length + vot * BA_Time

		//Select only assigned links, then set values
        SetView(join_vw)
        SelectByQuery("Traffic", "Several", "Select * Where ID1 > 0", )

        SetVs = null
        SetVs.("AB_"+per2+"_HwyS") = AB_Speed
        SetVs.("BA_"+per2+"_HwyS") = BA_Speed

        SetVs.("AB_"+per2+"_HwyT") = AB_Time
        SetVs.("BA_"+per2+"_HwyT") = BA_Time

        SetVs.("AB_"+per2+"_HwyC") = AB_Cost
        SetVs.("BA_"+per2+"_HwyC") = BA_Cost

        SetDataVectors(join_vw+"|Traffic", SetVs, )

        //Close files
		CloseView(join_vw)
		CloseView(flow_vw)
        DropLayerFromWorkspace(link_lyr)
        DropLayerFromWorkspace(node_lyr)

        //Highway Network will be re-created rather than just updated

	end //Loop over peak/off-peak
//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
    RunMacro("G30 File Close All")
    Return(1)
//EndStep

EndMacro  //End Speed Feedback

/***********************************************************************************************************************************
*
* Factor OD
* Macro factors trip tables by OD.  The macro writes one file for each period, containing the same number of cores as the input
* files, factored by time-of-day and PA/AP (to OD format).  The files will be written to the same directory as the input files.
* In addition, transposes of the input files will be written to that directory.
*
* Arguments:
*   inFiles             Array of input file names.  Each file must have exactly the same number of matrix cores.
*   outFile             Path/name of output file prefix - period will be appended for each output file.
*   perFactors          Array of period-specific factors dimensioned by mode, period, and input files  
*   apFactors           Array of attraction-production factors dimensioned by mode, period, and input files.
*   occFactors          Array of occupancy factors dimensioned by number of cores on input files.
*   modeIndex           Array of indexes dimensioned by number of cores on input files, relating each matrix core
*                       to a mode in the perFactors and apFactors tables.
*
***********************************************************************************************************************************/
Macro "Factor OD" (inFiles, outFile,perFactors, apFactors, occFactors, modeIndex, periodNames)

    dim matrixCurr[modeIndex.length]
    dim inTotals[inFiles.length, modeIndex.length]
    dim outTotals[periodNames.length, modeIndex.length]
        
    //open input trip tables and create transpose of trip files
    dim inMat [inFiles.length]
    dim inMat_T[inFiles.length]
    for i = 1 to inFiles.length do
        inMat[i] = OpenMatrix(inFiles[i],)
        
        //matrix totals
        inModeNames  = GetMatrixCoreNames(inMat[i])
        stat_array = MatrixStatistics(inMat[i],)
        
        for j = 1 to inModeNames.length do
            inTotals[i][j] = stat_array.(inModeNames[j]).Sum
        end
        
        //transpose
        pathSplit = SplitPath(inFiles[i])
        inMat_T[i] = TransposeMatrix(inMat[i], 
            { {"File Name", pathSplit[1]+pathSplit[2]+pathSplit[3]+"_TPS.MTX"},
              {"Label", "Operated Matrix"},
              {"Type", "Float"},
              {"Sparse", "No"},
              {"Column Major", "No"},
              {"File Based", "Yes"}})
    end

   //write the table for inputs to the report file
    AppendToReportFile(0, "Time-of-Day Factoring", {{"Section", "True"}})
    fileColumn = { {"Name", "File"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    modeColumns = null
    for i = 1 to inModeNames.length do
        modeColumns =   modeColumns + { { {"Name", inModeNames[i]}, {"Percentage Width", (100-20)/inModeNames.length}, {"Alignment", "Left"}, {"Decimals", 0} } }
    end
    columns = {fileColumn} + modeColumns
    AppendTableToReportFile( columns, {{"Title", "TOD Factor Input File Totals"}})

    for i = 1 to inFiles.length do
        pathSplit = SplitPath(inFiles[i])
        fileName = pathSplit[3]
        outRow = null
        for j = 1 to inModeNames.length do
            outRow =  outRow  + {inTotals[i][j] }
        end
        outRow = { fileName } + outRow  
        AppendRowToReportFile(outRow,)
    end

    //create period files for outputs
    dim outMat[periodNames.length]
    for i = 1 to periodNames.length do
        fileName = outFile+periodNames[i]+".mtx"
        //mc = OpenMatrix(inFiles[1],)
        //CopyMatrix(mc, {{"File Name", fileName}})
        CopyFile(inFiles[1],fileName)
        outMat[i] = OpenMatrix(fileName,)
    end

    //enter a loop on time periods
    for i = 1 to periodNames.length do
    
        // enter loop on files
        for j = 1 to inFiles.length do
    
            // open the input trip file
            mcurr  = CreateMatrixCurrencies(inMat[j], , ,)
            m_cores  = GetMatrixCoreNames(inMat[j])
            
            // enter loop on tables
            for k = 1 to m_cores.length do    
                
                // get the trip tables - input, input transposed, output
                inTrips     = mcurr.(m_cores[k])
                inTripsT    = CreateMatrixCurrency(inMat_T[j], m_cores[k], , , )
                outTrips    = CreateMatrixCurrency( outMat[i], m_cores[k], , , )
                
                //initialize the output matrix to 0 if the first file
                if(j = 1) then do
                    outTrips := 0
                end
                
                // get the factors 
                mode        = modeIndex[k]
                
                if(mode=0) then continue
                apFactor    = apFactors[mode][i][j]
                paFactor    = 1.0 - apFactor
                todFactor   = perFactors[mode][i][j]
                occFactor   = occFactors[k]
                  
                // calculate the output table
                outTrips := outTrips + (todFactor* occFactor * ( inTrips*paFactor + inTripsT*apFactor ) ) 
                	   
		    end
        end
    end                 

   // delete the transposed matrices  :: THROWS ERROR IN TC6; skipping for now
   /*  
   for i = 1 to inFiles.length do
        inMat_T[i] = null
        path = SplitPath(inFiles[i])
        DeleteFile(path[1]+path[2]+path[3]+"_TPS.MTX")
    end
*/
   // sum the output matrices
   for i = 1 to outMat.length do
        fileName = outFile+periodNames[i]+".mtx"
        outMat[i] = OpenMatrix(fileName,)
        outModeNames  = GetMatrixCoreNames(outMat[i])
        stat_array = MatrixStatistics(outMat[i],)
        
        for j = 1 to outModeNames.length do
            outTotals[i][j] = stat_array.(outModeNames[j]).Sum
        end

    end       
    
    //write the table for outputs to the report file
    fileColumn = { {"Name", "Period"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    modeColumns = null
    for i = 1 to outModeNames.length do
        modeColumns =   modeColumns + { { {"Name", inModeNames[i]}, {"Percentage Width", (100-20)/outModeNames.length}, {"Alignment", "Left"}, {"Decimals", 0} } }
    end
    columns = {fileColumn} + modeColumns
    AppendTableToReportFile( columns, {{"Title", "TOD Factor Output File Totals"}})

    for i = 1 to periodNames.length do
        outRow = null
        for j = 1 to outModeNames.length do
            outRow =  outRow  + {outTotals[i][j] }
        end
        outRow = { periodNames[i] } + outRow  
        AppendRowToReportFile(outRow,)
    end
    CloseReportFileSection()
    
    
    //ret_value = RunMacro("close all")
    //if !ret_value then goto quit
    
    Return(1)
     quit:
    	Return(1)
            
EndMacro

Macro "Process Land Use Data" (Args)
	shared UT, Scen
	
	bat_file = Args.[Process landuse]
    land_use = Args.[Land Use Data]
    output_dir_taz = Args.[TAZ Land Use Data]
    anaconda_dir = Args.[Anaconda_DIR]
    env_dir = Args.[ENV_DIR]
    env_name = Args.[PYTHON_ENV_NAME]
    output_dir = Args.Info.[Output Directory]
	iteration = Scen.Feedback.iteration
    other_zonal_data_dir = Args.[Other Zonal Data]
    merged_landuse_data_dir = Args.[Merged Land Use Data]

	status = null
	status=RunProgram(bat_file + " " + String(iteration) + " " + land_use + " " + output_dir_taz + " " + anaconda_dir + " " + env_dir + " " + output_dir + " " + env_name + " " + other_zonal_data_dir + " " + merged_landuse_data_dir, {{"Maximize", "True"}})

	if status<>0 then do
		ShowMessage ("Process land use Failed!")
		goto quit
	end

	ok = 1
    return(ok)

    quit:
		return(0)

endMacro

Macro "Airport Model" (Args)
 //read in data
  TAZ_path = Args.[TAZ]
  SEDataFile =  Args.[TAZ Land Use Data]
  AirpottDataFile = Args.[Airport data]
  AutoSkimFile = Args.AMHwySkims
  OD_path_ = Args.[EXT Airport]
  path = Splitpath(OD_path_)
  OD_path = path[1] + path[2]
  
  //output = Args.[Summary Report]
  //path = Splitpath(output)
  //OD_path = path[1] + path[2] + '\\EXT_Airport'
  //CreateDirectory(OD_path)
  //OD_output = Args.[OD Trip Tables]
  // construct airport/od path dir
  //path_ = SplitPath(TAZ_path)
  //airport_path = path_[1] + path_[2]

  //path_ = SplitPath(OD_output)
  //OD_path = path_[1] + path_[2]

  //inputDir = "C:\\RSG_test\\semcog\\Model_Runs\\SEMCOG_ABM_2.3\\Input"
  //outputDir = "C:\\RSG_test\\semcog\\Model_Runs\\SEMCOG_ABM_2.4\\Output"
  //AirpottDataFile =  airport_path + '\Airport_STrip_2020.bin' //inputDir + "\\SED\\Airport_STrip_2020.bin"
    
  //occupancy = 1.3
  //tripsPerPassenger = 1.7
  //localShare = 0.5

  //airportTaz1  = 682
  //airportTaz2  = 683
  //dailyEnplanements1 = 33200
  //dailyEnplanements2 = 16600

  percentResident = 0.3
  cLogsum = 1.0
  cTime = -0.028
  cCost = -0.003
  autoOperatingCost = 18.29


  //Open SEData and airport data file
  SE_DATA = OpenTable("SEDATA","CSV",{SEDataFile})
  ViewSE = SE_DATA + "|"

  ArView 		= OpenTable("Airport","FFB",{AirpottDataFile})
  ViewAr		= ArView + "|"
  
  // Read data from Airport Data File
  airportTaz = GetDataVector(ViewAr, "ID",)
  dailyEnplanements = GetDataVector(ViewAr, "Enplanement",)
  occupancy_ = GetDataVector(ViewAr, "VehicleOccupancy",)
  tripsPerPassenger_ = 1 + GetDataVector(ViewAr, "ServiceTripsPerPassenger",)
  localShare_ = GetDataVector(ViewAr, "LocalShare",)
  
  occupancy = occupancy_[1]
  tripsPerPassenger = tripsPerPassenger_[1]
  localShare = localShare_[1]


  //Read Distance
  AutoSkimMat = OpenMatrix(AutoSkimFile, "Auto")
  AutoCores = GetMatrixCoreNames(AutoSkimMat)
  auto_dist = CreateMatrixCurrency(AutoSkimMat, "Miles", "ZoneID", "ZoneID", null)
  //auto_time = CreateMatrixCurrency(AutoSkimMat, "Trav_Time", "ZoneID", "ZoneID", null)
	 
  //Create trip table
  matrixName = OD_path + "\\PA_AIRPORT.mtx"
  tripMat =CreateMatrix({ViewSE, "zoneid", "Row Index"},
  		{ViewSE, "zoneid", "Column Index"},
  		{{"File Name", matrixName}, {"Type", "Float"}, , {"Tables", {"Trips"}}, {"OMX", False}})
  tripCurr = CreateMatrixCurrency(tripMat, "Trips", "Row Index", "Column Index", null)

  //Create temp matrix for utilities, exp utilities, prob
  temp_airport = OD_path + "\\TEMP_AIRPORT.mtx"
  tempMat =CreateMatrix({ViewSE, "zoneid", "Row Index"},
  		{ViewSE, "zoneid", "Column Index"},
  		{{"File Name", temp_airport}, {"Type", "Float"}, , {"Tables", {"Util","ExpUtil","Prob"}}})
  utilCurr = CreateMatrixCurrency(tempMat, "Util", "Row Index", "Column Index", null)
  expUtilCurr = CreateMatrixCurrency(tempMat, "ExpUtil", "Row Index", "Column Index", null)
  probCurr = CreateMatrixCurrency(tempMat, "Prob", "Row Index", "Column Index", null)
  
  //total trips
  percentVisitor = 1.0 - percentResident 
  totalTrips1 = dailyEnplanements[1] * localShare * 2.0 * 1/occupancy * tripsPerPassenger
  totalTrips2 = dailyEnplanements[2] * localShare* 2.0 * 1/occupancy * tripsPerPassenger

  residentParameter = percentResident/percentVisitor
  
  //size terms--Only have hh, no hotel data for SEMCOG
  households = nz(GetDataVector(ViewSE, "tot_hhs", {{"Sort Order",{{"zoneid","Ascending"}}},{"Type","Double"}}))
  householdMean = VectorStatistic(households,"Mean",)
	
  tazs =  nz(GetDataVector(ViewSE, "zoneid", {{"Sort Order",{{"zoneid","Ascending"}}}}))

  logSize = if((households) > 0) then Log(residentParameter * households) else 0
  logSize.rowbased = true
  logSize.columnbased = false
  
  productions = Vector(households.length, "Double", {{"Constant", 0},{"Column Based", "True"}})
  
  productions.rowbased=false
  productions.columnbased = true
  for i = 1 to productions.length do
    if(tazs[i] = airportTaz[1]) then productions[i] = totalTrips1 else if (tazs[i] = airportTaz[2]) then productions[i] = totalTrips2 else productions[i]=0
  end
   
  //create trip table
  utilCurr :=  if(logSize > 0) then cLogsum * (cCost * auto_dist * autoOperatingCost ) + logSize	else 0
  expUtilCurr := if(utilCurr <> 0) then Exp(utilCurr) else 0
  
  //summing for each row (really a column vector)
  sumExpUtilities = GetMatrixMarginals(expUtilCurr, "Sum", "row" )
  rowSums = ArrayToVector(sumExpUtilities)
  rowSums.columnbased=true
  rowSums.rowbased=false
  	        	      
  probCurr := if(rowSums > 0) then expUtilCurr/rowSums else 0
  tripCurr := productions * probCurr
  
  //Factor to TOD
  perFactors ={{ {0.12} ,     // AM 
                {0.33} ,        // MD  
                {0.32} ,       // PM      
                {0.19},        // EV
                {0.03} }}      // EA         
                    
                
  // assume symmetry in each period
  apFactors = { { { 0.5} ,      // AM Peak           
            { 0.5} ,      // MD      
            { 0.5},       //PM
            {0.5},        //EV
            {0.5} } }    // EA           
                                
            
  modeIndex = { 1 }  
  occFactors = { 1 }

  outFile = OD_path + "\\AIRPORT_"
  outPeriods={"AM","MD","PM", "EV", "EA"}

  ret_value = RunMacro("Factor OD",{matrixName},outFile,perFactors,apFactors,occFactors,modeIndex,outPeriods)
    if !ret_value then goto quit

  for i = 1 to outPeriods.length do
    file_name = outFile + outPeriods[i] + '.mtx'
    mtx_ = openmatrix(file_name,)
    mtx = CreateMatrixCurrency(mtx_,,,,)
    omx_file = Substitute(file_name, ".mtx", ".omx", )
    copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 0}
    CopyMatrix(mtx, copy_matrix_options)
  end

  quit:
    Return(1)
EndMacro

Macro "EI Model" (Args)
 //shared inputDir, outputDir 
  TAZ_path = Args.[TAZ]
  SEDataFile =  Args.[TAZ Land Use Data]
  ExternaltDataFile = Args.[Person IEEI file]
  AutoSkimFile = Args.AMHwySkims
  OD_path_ = Args.[EXT Airport]
  path = Splitpath(OD_path_)
  OD_path = path[1] + path[2]

  cCost = -0.007
  autoOperatingCost = 18.29
  occ_factor = 1.0 //already vehicle trip format

  //Open SEData and airport data file
  SE_DATA = OpenTable("SEDATA","CSV",{SEDataFile})
  ViewSE = SE_DATA + "|"

  ExternalView 		= OpenTable("Extenral","FFB",{ExternaltDataFile})
  ViewEx		= ExternalView + "|"
  
  // Read in External TAZs' P/A 
  ExTaz = GetDataVector(ViewEx, "TAZ",)
  Ex_P = GetDataVectors(ViewEx, {"HBW_P", "HBSH_P", "HBSC_P", "HBUniv_P", "HBO_P", "NHBW_P", "NHBO_P"},)
  Ex_A = GetDataVectors(ViewEx, {"HBW_A", "HBSH_A", "HBSC_A", "HBUniv_A", "HBO_A", "NHBW_A", "NHBO_A"},)

  //total Production is sum over all purps
  EX_P_sum = (Ex_P[1] + Ex_P[2] + Ex_P[3] + Ex_P[4] + Ex_P[5] + Ex_P[6] + Ex_P[7])/occ_factor
  EX_A_sum = Ex_A[1] + Ex_A[2] + Ex_A[3] + Ex_A[4] + Ex_A[5] + Ex_A[6] + Ex_A[7]

  //Read Distance
  AutoSkimMat = OpenMatrix(AutoSkimFile, "Auto")
  AutoCores = GetMatrixCoreNames(AutoSkimMat)
  auto_dist = CreateMatrixCurrency(AutoSkimMat, "Miles", "ZoneID", "ZoneID", null)
  //auto_time = CreateMatrixCurrency(AutoSkimMat, "Trav_Time", "ZoneID", "ZoneID", null)
	 
  //Create trip table
  matrixName = OD_path + "\\PA_EI.mtx"
  tripMat =CreateMatrix({ViewSE, "zoneid", "Row Index"},
  		{ViewSE, "zoneid", "Column Index"},
  		{{"File Name", matrixName}, {"Type", "Float"}, , {"Tables", {"Trips"}}, {"OMX", False}})
  tripCurr = CreateMatrixCurrency(tripMat, "Trips", "Row Index", "Column Index", null)

  //Create temp matrix for utilities, exp utilities, prob
  temp_ex = OD_path + "\\TEMP_EXTERNAL.mtx"
  tempMat =CreateMatrix({ViewSE, "zoneid", "Row Index"},
  		{ViewSE, "zoneid", "Column Index"},
  		{{"File Name", temp_ex}, {"Type", "Float"}, , {"Tables", {"Util","ExpUtil","Prob"}}})
  utilCurr = CreateMatrixCurrency(tempMat, "Util", "Row Index", "Column Index", null)
  expUtilCurr = CreateMatrixCurrency(tempMat, "ExpUtil", "Row Index", "Column Index", null)
  probCurr = CreateMatrixCurrency(tempMat, "Prob", "Row Index", "Column Index", null)

  
  //size terms -- household
  emp = nz(GetDataVector(ViewSE, "tot_emp", {{"Sort Order",{{"zoneid","Ascending"}}},{"Type","Double"}}))
	
  tazs =  nz(GetDataVector(ViewSE, "zoneid", {{"Sort Order",{{"zoneid","Ascending"}}}}))

  logSize = if((emp) > 0) then Log(emp) else 0
  logSize.rowbased = true
  logSize.columnbased = false
  
  productions = Vector(emp.length, "Double", {{"Constant", 0},{"Column Based", "True"}})
  
  productions.rowbased=false
  productions.columnbased = true
  for i = 1 to ExTaz.length do
    productions[ExTaz[i]] = EX_P_sum[i]
  end
   
  //create trip table
  utilCurr :=  if(logSize > 0) then (cCost * auto_dist * autoOperatingCost) + logSize	else 0
  expUtilCurr := if(utilCurr <> 0) then Exp(utilCurr) else 0
  
  //summing for each row (really a column vector)
  sumExpUtilities = GetMatrixMarginals(expUtilCurr, "Sum", "row" )
  rowSums = ArrayToVector(sumExpUtilities)
  rowSums.columnbased=true
  rowSums.rowbased=false
  	        	      
  probCurr := if(rowSums > 0) then expUtilCurr/rowSums else 0
  tripCurr := productions * probCurr
  
  //Factor to TOD
  perFactors ={ { {0.18} ,     // AM 
                {0.35} ,        // MD  
                {0.32} ,       // PM      
                {0.13},        // EV
                {0.02} }}      // EA          
                    
                
  // assume symmetry in each period
  apFactors = {{ { 0.5} ,      // AM Peak           
            { 0.5} ,      // MD      
            { 0.5},       //PM
            {0.5},        //EV
            {0.5} }}    // EA           
                                
            
  modeIndex = { 1 }  
  occFactors = { 1 }

  outFile = OD_path + "\\EI_OD_"
  outPeriods={"AM","MD","PM", "EV", "EA"}

  ret_value = RunMacro("Factor OD",{matrixName},outFile,perFactors,apFactors,occFactors,modeIndex,outPeriods)
    if !ret_value then goto quit

  for i = 1 to outPeriods.length do
    file_name = outFile + outPeriods[i] + '.mtx'
    mtx_ = openmatrix(file_name,)
    mtx = CreateMatrixCurrency(mtx_,,,,)
    omx_file = Substitute(file_name, ".mtx", ".omx", )
    copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 0}
    CopyMatrix(mtx, copy_matrix_options)
  end

  quit:
    Return(1)
EndMacro

Macro "IE Model" (Args)

  TAZ_path = Args.[TAZ]
  SEDataFile =  Args.[TAZ Land Use Data]
  AutoSkimFile = Args.AMHwySkims
  ExternaltDataFile = Args.[Person IEEI file]
  OD_path_ = Args.[EXT Airport]
  path = Splitpath(OD_path_)
  OD_path = path[1] + path[2]

  cTime = -0.028
  cCost = -0.007
  autoOperatingCost = 18.29
  occ_factor = 1.0 //already in vehicle trip format 

  //Open SEData and airport data file
  SE_DATA = OpenTable("SEDATA","CSV",{SEDataFile})
  ViewSE = SE_DATA + "|"

  ExternalView 		= OpenTable("Extenral","FFB",{ExternaltDataFile})
  ViewEx		= ExternalView + "|"
  
  // Read in External TAZs' P/A 
  ExTaz = GetDataVector(ViewEx, "TAZ",)
  //Ex_P = GetDataVectors(ViewEx, {"HBW_P", "HBSH_P", "HBSC_P", "HBUniv_P", "HBO_P", "NHBW_P", "NHBO_P"},)
  Ex_A = GetDataVectors(ViewEx, {"HBW_A", "HBSH_A", "HBSC_A", "HBUniv_A", "HBO_A", "NHBW_A", "NHBO_A"},)

  //total Production is sum over all purps
  //EX_P_sum = Ex_P[1] + Ex_P[2] + Ex_P[3] + Ex_P[4] + Ex_P[5] + Ex_P[6] + Ex_P[7]
  EX_A_sum = (Ex_A[1] + Ex_A[2] + Ex_A[3] + Ex_A[4] + Ex_A[5] + Ex_A[6] + Ex_A[7])/occ_factor

  //Read Distance
  AutoSkimMat = OpenMatrix(AutoSkimFile, "Auto")
  AutoCores = GetMatrixCoreNames(AutoSkimMat)
  auto_dist = CreateMatrixCurrency(AutoSkimMat, "Miles", "ZoneID", "ZoneID", null)
  //auto_time = CreateMatrixCurrency(AutoSkimMat, "Trav_Time", "ZoneID", "ZoneID", null)
	 
  //Create trip table
  matrixName = OD_path + "\\PA_IE.mtx"
  tripMat =CreateMatrix({ViewSE, "zoneid", "Row Index"},
  		{ViewSE, "zoneid", "Column Index"},
  		{{"File Name", matrixName}, {"Type", "Float"}, , {"Tables", {"Trips"}}, {"OMX", False}})
  tripCurr = CreateMatrixCurrency(tripMat, "Trips", "Row Index", "Column Index", null)

  //Create temp matrix for utilities, exp utilities, prob
  temp_ex = OD_path + "\\TEMP_EXTERNAL.mtx"
  tempMat =CreateMatrix({ViewSE, "zoneid", "Row Index"},
  		{ViewSE, "zoneid", "Column Index"},
  		{{"File Name", temp_ex}, {"Type", "Float"}, , {"Tables", {"Util","ExpUtil","Prob"}}})
  utilCurr = CreateMatrixCurrency(tempMat, "Util", "Row Index", "Column Index", null)
  expUtilCurr = CreateMatrixCurrency(tempMat, "ExpUtil", "Row Index", "Column Index", null)
  probCurr = CreateMatrixCurrency(tempMat, "Prob", "Row Index", "Column Index", null)
  
  //size terms -- household
  emp = nz(GetDataVector(ViewSE, "tot_emp", {{"Sort Order",{{"zoneid","Ascending"}}},{"Type","Double"}}))
	
  tazs =  nz(GetDataVector(ViewSE, "zoneid", {{"Sort Order",{{"zoneid","Ascending"}}}}))

  logSize = if((emp) > 0) then Log(emp) else 0
  logSize.rowbased = true
  logSize.columnbased = false
  
  productions = Vector(emp.length, "Double", {{"Constant", 0},{"Column Based", "True"}})
  
  productions.rowbased=false
  productions.columnbased = true
  for i = 1 to ExTaz.length do
    productions[ExTaz[i]] = EX_A_sum[i]
  end
   
  //create trip table
  utilCurr :=  if(logSize > 0) then (cCost * auto_dist * autoOperatingCost) + logSize	else 0
  expUtilCurr := if(utilCurr <> 0) then Exp(utilCurr) else 0
  
  //summing for each row (really a column vector)
  sumExpUtilities = GetMatrixMarginals(expUtilCurr, "Sum", "row" )
  rowSums = ArrayToVector(sumExpUtilities)
  rowSums.columnbased=true
  rowSums.rowbased=false
  	        	      
  probCurr := if(rowSums > 0) then expUtilCurr/rowSums else 0
  tripCurr := productions * probCurr
  
  //Factor to TOD
  perFactors ={ { {0.18} ,     // AM 
                {0.35} ,        // MD  
                {0.32} ,       // PM      
                {0.13},        // EV
                {0.02} }}      // EA         
                    
                
  // assume symmetry in each period
  apFactors = { { { 0.5} ,      // AM Peak           
            { 0.5} ,      // MD      
            { 0.5},       //PM
            {0.5},        //EV
            {0.5} } }    // EA           
                                
            
  modeIndex = { 1 }  
  occFactors = { 1 }

  outFile = OD_path + "\\IE_OD_"
  outPeriods={"AM","MD","PM", "EV", "EA"}

  ret_value = RunMacro("Factor OD",{matrixName},outFile,perFactors,apFactors,occFactors,modeIndex,outPeriods)
    if !ret_value then goto quit

  for i = 1 to outPeriods.length do
    file_name = outFile + outPeriods[i] + '.mtx'
    mtx_ = openmatrix(file_name,)
    mtx = CreateMatrixCurrency(mtx_,,,,)
    omx_file = Substitute(file_name, ".mtx", ".omx", )
    copy_matrix_options = {"File Name": omx_file, "OMX":"True", "Compression": 0}
    CopyMatrix(mtx, copy_matrix_options)
  end

  quit:
    Return(1)
EndMacro

// *****************************************************************************
// Step Assignment Combine:
Macro "SEMCOG Assignment Combine" (Args)
//       - Combines period assignment results into a daily total
//          --> Values can be summed or averaged (speed averages use the harmonic mean)
//       - Adds selected period and daily values to the roadway network
// *****************************************************************************
	//Load information
	shared canned, ret_value, NextStep
	shared util_ui, UT



NextStep= "Define files and fields"
SetStatus(1, NextStep, )

	//Load tables/params
	SubPers = Args.HwySubPeriods
    HwyPers = Args.HwyPeriods

	//define input files
	qry_file = Args.[Crit_Query]

	//Define intermediate files
	dbd_file = Args.[Highway DB]
    flow_files1 = Args.[Highway Flows]
    sel_files1 = Args.SelectMatrix


    //Expand flow and select files using 2 levels
    dim flow_files[SubPers.length], sel_files[SubPers.length]

    for ii = 1 to SubPers.length do
        dim tmp[SubPers[ii].length]
        flow_files[ii] = CopyArray(tmp)
        sel_files[ii] = CopyArray(tmp)

        for jj = 1 to SubPers[ii].length do
            flow_files[ii][jj] = Substitute(flow_files1, "%PER_HWY%", SubPers[ii][jj], )
            sel_files[ii][jj] = Substitute(sel_files1, "%PER_HWY%", SubPers[ii][jj], )
        end

    end

	od_fileMD = Substitute(Args.[OD Trip Tables], "%PER_HWY%", "MD", ) //Used only to get core names (vehicle classes)
    excl_cores = {"Airport"} //Matrix cores in the OD table excluded from assignment

	//Select query matrix output from assignment
	t = SplitPath(flow_files[1][1])
	asn_dir = t[1]+t[2]
	t = null
	if (GetFileInfo(qry_file) = null) then run_select = False
	else do
	    run_select = True
		for _per = 1 to SubPers.length do
			for _subper = 1 to SubPers[_per].length do
				if GetFileInfo(sel_files[_per][_subper]) = null then do
					run_select = False
					goto NoSelectCombine
				end //if no file
			end //_subper
		end //_per loop
        t = SplitPath(sel_files[1][1])
		sel_day_file = Substitute(sel_files1, "%PER_HWY%", "DY", )
	end // qry file exists
	NoSelectCombine: //If one or more select link output matrices is missing, quit the loop.


    //Detect fields in the flow table, determine if we are using VMT or V_Dist_T, and get IDs
    flow_vw = OpenTable("tmp", "FFB", {flow_files[1][1]})
    {FlowFields, } = GetFields(flow_vw, )
    link_IDs = GetDataVector(flow_vw+"|", "ID1", )

    if ArrayPosition(FlowFields, {"AB_VMT"}, ) > 0 then vmt_name = "M"
    else vmt_name = "_Dist_"

    CloseView(flow_vw)
    flow_vw = null

	//Define Output Files
	asn_day_file = Args.[DY Highway Flows]

	//Define fields to accumulate (sum)

	sum_flds = {"AB_V"+vmt_name+"T",
				"BA_V"+vmt_name+"T",
				"TOT_V"+vmt_name+"T",
				"AB_VHT",
				"BA_VHT",
				"TOT_VHT"}


	//Add class flows to the sum list
	mat = OpenMatrix(od_fileMD, )
	veh_cores = GetMatrixCoreNames(mat)
    veh_classes = null
    for ii = 1 to veh_cores.length do //Exclude specified cores
        if ArrayPosition(excl_cores, {veh_cores[ii]}, ) = 0 then
        veh_classes = veh_classes + {veh_cores[ii]}
    end

	mat = null
	for i = 1 to veh_classes.length do
		sum_flds = sum_flds + {"AB_Flow_"+veh_classes[i],
								"BA_Flow_"+veh_classes[i]}
	end

	sum_flds = sum_flds + {"AB_Flow_PCE",
							"BA_FLOW_PCE",
							"Tot_Flow_PCE",
							"AB_Flow",
							"BA_Flow",
							"TOT_Flow"}

	//Add select link/node fields to the sum list
	if run_select then do
		//Get query names
		mat = OpenMatrix(sel_files[1][1], )
		select_cores = GetMatrixCoreNames(mat)  //Select matrix core names
		mat = null
		select_names = null
		for i = 1 to select_cores.length do
			if Right(select_cores[i], 1) <> "]" then do
				select_names = select_names + {select_cores[i]}
			end
		end

		//Select assignment field name extensions
		select_flds = null
		for i = 1 to select_names.length do
			select_flds = select_flds + {"AB_Flow_"+select_names[i],
										"BA_Flow_"+select_names[i]}
		end

		if select_flds <> null then sum_flds = sum_flds + select_flds
	end

	//Define fields to average / calculate
	avg_flds = {"AB_VOC",
				"BA_VOC", //need max
				"AB_Time",
				"BA_Time",//need max
				"AB_Speed",
				"BA_Speed"}

	wt_flds = {"AB_V"+vmt_name+"T",  //Fields to use when weighting averages
			   "BA_V"+vmt_name+"T",
			   "AB_V"+vmt_name+"T",
			   "AB_V"+vmt_name+"T",
			   "AB_VHT", //use harmonic mean for speed
			   "BA_VHT"} //use harmonic mean for speed
	//These fields are only available in the hourly flow tables:
	// - *_VDF,
	// - Some MSA fields

//EndStep
NextStep= "Define Flow Table Structure"
SetStatus(1, NextStep, )

	//Define fields to include in new tables
	table_flds = {{"ID1", "I", 8, 0}}

	//Add avg fields to the filed list
	for i = 1 to avg_flds.length do
		table_flds = table_flds + {{avg_flds[i], "R", 10, 4}}
	end

	//Add sum fields to the filed list
	for i = 1 to sum_flds.length do
		table_flds = table_flds + {{sum_flds[i], "R", 10, 4}}
	end

	//Initialize array to hold daily totals/averages
	dim day_sum_values[sum_flds.length]
	dim day_avg_numerators[avg_flds.length]  //numerators for average calculations
	dim day_avg_denom[avg_flds.length]  //denominator for average calculations

	//Create empty select link/node total daily trip table
	if run_select then do
		mat = OpenMatrix(sel_files[1][1], )
		cur = CreateMatrixCurrency(mat, select_cores[1], , , )
		Opts = null
		Opts.[File Name] = sel_day_file
		Opts.[Label] = "Select Link Trips (Daily)"
		Opts.Tables = select_cores
		CopyMatrixStructure({cur}, Opts)

        //Add a ZoneID core to the daily matrix
		ok = RunMacro("Add Matrix Zone ID Index", sel_day_file, Args)
		if !ok then Return()

        selday_mat = OpenMatrix(sel_day_file, )
		selday_curs = CreateMatrixCurrencies(selday_mat, "ZoneID", "ZoneID", )

		cur = null
		mat = null
	end

	//Progress bar setup
	prog_stat = 0
	prog_tot = 0
	for _per = 1 to SubPers.length do
		prog_tot = prog_tot + SubPers[_per].length
	end
	CreateProgressBar("Combining Time Periods...", "True")

	//Loop over periods
	for _per = 1 to SubPers.length do
		for _subper = 1 to SubPers[_per].length do

			//Progress Bar
			prog_stat = prog_stat + 1
			canned = UpdateProgressBar("Combining Data for "+SubPers[_per][_subper],  r2i(prog_stat / prog_tot * 100))
			if canned then Return()
//EndStep
NextStep= "Accumulate Values"
SetStatus(1, NextStep, )

			//Open sub-period flow table
			flow_vw = OpenTable("Hourly Flows", "FFB", {flow_files[_per][_subper], })

			//Accumulate Sum Values
			for k = 1 to sum_flds.length do
				V = nz(GetDataVector(flow_vw+"|", sum_flds[k], ))
				day_sum_values[k] = nz(day_sum_values[k]) + V
			end //k loop (sum fields)

			//Accumulate Average Values (numerators and denominators)
			for k = 1 to avg_flds.length do
				expr = CreateExpression(flow_vw, "myNUM", avg_flds[k] + "*"+wt_flds[k], {{"Type", "Real"}, {"Decimals", 10}})
				V = nz(GetDataVector(flow_vw+"|", expr, ))
				day_avg_numerators[k] = nz(day_avg_numerators[k]) + V
				DestroyExpression(flow_vw+"."+expr)
				V = nz(GetDataVector(flow_vw+"|", wt_flds[k], ))
				day_avg_denom[k] = nz(day_avg_denom[k]) + V
			end //k loop (sum fields)

			//Accumulate matrix values
			if run_select then do
				sel_mat = OpenMatrix(sel_files[_per][_subper], )
				sel_curs = CreateMatrixCurrencies(sel_mat, "ZoneID", "ZoneID", )
				for k = 1 to select_cores.length do
					selday_curs.(select_cores[k]) := nz(selday_curs.(select_cores[k])) + nz(sel_curs.(select_cores[k]))
				end
                sel_mat = null
                sel_curs = null
			end

		end //_subper
	end // _per
	DestroyProgressBar()

	//Close daily matrix
	selday_curs = null
	selday_mat = null

//EndStep
NextStep= "Write Daily Totals"
SetStatus(1, NextStep, )

	//Create the daily table
	asn_day_vw = CreateTable("DailyFlows", asn_day_file, "FFB", table_flds)
	AddRecords(asn_day_vw, , , {{"Empty Records", link_IDs.length}})
	SetDataVector(asn_day_vw+"|", "ID1", link_IDs, )

	//Fill hourly sum data
	CreateProgressBar("Writing Daily Totals...", "True")
	for i = 1 to sum_flds.length do
		canned = UpdateProgressBar("Writing Daily Totals...", r2i(i / sum_flds.length * 100))
		if canned then Return()
		SetDataVector(asn_day_vw+"|", sum_flds[i], day_sum_values[i], )
	end
	DestroyProgressBar()

	//Fill daily average data
	CreateProgressBar("Writing Daily Averages...", "True")
	for j = 1 to avg_flds.length do
		canned = UpdateProgressBar("Writing Daily Averages...", r2i(j / avg_flds.length * 100))
		if canned then Return()
		SetDataVector(asn_day_vw+"|", avg_flds[j], day_avg_numerators[j] / day_avg_denom[j], )
	end

    //Write to csv added for CVM update
	t = SplitPath(asn_day_file)
	daily_flows = t[1] + t[2] + "Flow_DY.csv"
	ExportView(asn_day_vw+"|", "CSV", daily_flows, null, {{"CSV Header", "True"}}) // write asn day view to csv file

    for i = 1 to HwyPers.length do
	  flow_file_tp = Substitute(flow_files1, "%PER_HWY%", HwyPers[i], )
  	flow_vw = OpenTable("tmp", "FFB", {flow_file_tp})
  	tp_flows = Substitute(flow_file_tp, ".bin", ".csv", )
  	ExportView(flow_vw+"|", "CSV", tp_flows, null, {{"CSV Header", "True"}}) // write asn tp view to csv file
  	CloseView(flow_vw)
	end 

	DestroyProgressBar()


    if run_select then do
//EndStep
NextStep= "Select Summary Table"
SetStatus(1, NextStep, )

        Fields = {{"TAZ", "Integer", 8, }}
        for s in select_names do
            Fields = Fields + {{s+"_Origins", "Real", 10, 2},
                               {s+"_Destinations", "real", 10, 2}}
        end

        select_pers = SubPers.flatten() + {"DY"} //convert to a simple 1D array, add daily
        select_files2 = sel_files.flatten() + {sel_day_file}

        for _per = 1 to select_pers.length do
            per = select_pers[_per]
            select_file = select_files2[_per]

            //read row and column totals
            SetVs = null
            mat = OpenMatrix(select_file, )
            for ii = 1 to select_names.length do
                cur = CreateMatrixCurrency(mat, select_names[ii], "ZoneID", "ZoneID", )

                //Get TAZs on first loop
                if ii = 1 then do
                    SetVs.TAZ = GetMatrixVector(cur, {{"Index", "Row"}})
                end

                SetVs.(select_names[ii]+"_Origins") = GetMatrixVector(cur, {{"Marginal", "Row Sum"}})
                SetVs.(select_names[ii]+"_Destinations") = GetMatrixVector(cur, {{"Marginal", "Column Sum"}})

                cur = null
            end //ii = select_names
            mat = null

            //Create the TAZ table with select link row/col sums
            t = SplitPath(select_file)
            select_sum_file = t[1]+t[2]+"SelectSummary_"+per+".bin"
            select_vw = CreateTable("SelectSummary_"+per, select_sum_file, "FFB", Fields)

            AddRecords(select_vw, , , {[Empty Records]:SetVs.TAZ.Length})
            SetDataVectors(select_vw+"|", SetVs, )

            CloseView(select_vw)
        end //_per

    end //run_select


//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
	RunMacro("G30 File Close All")
	Return(1)
//EndStep
EndMacro


/***********************************************************************************
 Transit Assignment  - updated to 4 periods by JChen in July 2015
**********************************************************************************/

Macro "SEMCOG Transit Assignment" (Args)
    shared nOper, TransCADVersion, scen_data_dir, OutDir
    shared UT
//    SetStatus(2,"Transit Assignments",)

    // Path
    OutDir = scen_data_dir + "out\\"

    // Inputs
    db_file = Args.[Highway DB]
    rs_file = Args.[Route System]

    //Intermediates
    tnw_files = UT.Expand(Args.[Transit Network])
    od_files = UT.Expand(Args.[Transit OD Trip Tables])

    // Outputs
    NestOpt = {{"NestOrder", {"PER_TRN", "TMODE", "AMODE"}}}
    tflow_files = UT.Expand(Args.[Transit Flow Files], NestOpt)
    wflow_files = UT.Expand(Args.[Transit Walk Files], NestOpt)
    aflow_files = UT.Expand(Args.[Transit Agg Files], NestOpt)
    onoff_files = UT.Expand(Args.[Transit OnOff Files], NestOpt)
/*
    Periods  = {"AM"}
    Modes       = {"Bus"}   // List of transit modes
    ModeCode    = {"AB"}   // List of transit mode codes
    AccessModes = {"DRV"}
*/

    Periods  = {"EA", "AM", "MD", "PM", "EV"}
    Modes       = {"LOC", "PRM", "MIX"}   // List of transit modes
    AccessModes = {"WLK", "PNR", "KNR", "PNRE", "KNRE"}//Added for Transit Drive Egress AWalker Nov. 2016

    for period = 1 to Periods.length do
      for imode = 1 to Modes.length do
        for iacc = 1 to AccessModes.length do

          period_s = Periods[period]
          mode_t = Modes[imode]
		  access = AccessModes[iacc]

	      tnw_file = tnw_files[period]

		if access = "KNRE" then do
          tflowFile = Substitute(tflow_files[period][imode][iacc-1], "DRVE", "KNRE",)
          wflowFile = Substitute(wflow_files[period][imode][iacc-1], "DRVE", "KNRE",)
          aflowFile = Substitute(aflow_files[period][imode][iacc-1], "DRVE", "KNRE",)
          onoffFile = Substitute(onoff_files[period][imode][iacc-1], "DRVE", "KNRE",)
		end
		else do
		tflowFile = tflow_files[period][imode][iacc]
        wflowFile = wflow_files[period][imode][iacc]
        aflowFile = aflow_files[period][imode][iacc]
        onoffFile = onoff_files[period][imode][iacc]
		end

          //Assign KnR trips using the walk network settings
          //use_access = if access = "KNR" then "WLK" else access

		use_access = access

		if access = "PNR" then do
		  	use_access = "DRV"
		end
		if access = "PNRE" then do
		  	use_access = "DRVE"
		end
		if access = "KNR" or access = "KNRE" then do
		  	use_access = "WLK"
		end

		//if mode_t = "LOC" then do
		//	use_mode = "Local"
		//end
		//if mode_t = "PRM" then do
		//	use_mode = "Premium"
		//end
		//if mode_t = "MIX" then do
		//	use_mode = "Mix"
		//end

    	  ok = RunMacro("SEMCOG Set Transit Network",Args, period_s, mode_t, use_access)
    	  if !ok then goto exit

          SetStatus(1, "Transit Assignment for " + Periods[period]+" "+Modes[imode] +" "+AccessModes[iacc],)
    //=================================================================================

		  od_mat = Substitute(od_files[period], ".mtx", ".OMX", )
		  ret_value = RunMacro("Add Matrix Node ID Index", od_mat, Args)
          if !ret_value then goto exit

		  if access = "WLK" then do
			  access = "WALK"
		  end

		  Opts = null
	      Opts.Input.[Transit RS]         = rs_file
	      Opts.Input.Network              = tnw_file
          Opts.Input.[OD Matrix Currency] = {od_mat, access + "_" + mode_t, "NodeID", "NodeID"}
          Opts.Global.[OD Layer Type] = "Node"
	      Opts.Output.[Flow Table]        = tflowFile
	      Opts.Output.[Walk Flow Table]   = wflowFile
          Opts.Output.[Aggre Table]       = aflowFile
	      Opts.Output.[OnOff Table]       = onoffFile

          ok = RunMacro("TCB Run Procedure", 1, "Transit Assignment PF", Opts)
		  if !ok then goto exit

        //The transit assignment macro leaves a map open, so close all maps:
        maps = GetMaps()
        if maps != null then do
            for i = 1 to maps[1].length do
                SetMapSaveFlag(maps[1][i], "False")
                CloseMap(maps[1][i])
            end
        end
        maps = null



	    end  //end access mode
      end // end transit mode
    end  // end period mode

    exit:

    SetStatus(1, "@System0",)
    Return(ok)
EndMacro

// ****************************************************************************************************************
Macro "SEMCOG Transit Combine" (Args)
    //Load information
    shared canned, ret_value, NextStep, UT


NextStep= "Define files and data"
SetStatus(1, NextStep, )

	//Define input files
    rts_file = Args.[Route System]
    tdbd_file = Args.[Highway DB]

    //Define intermediate files

	tflow_files = UT.Expand(Args.[Transit Flow Files], NestOpt)
	wflow_files = UT.Expand(Args.[Transit Walk Files], NestOpt)
	aflow_files = UT.Expand(Args.[Transit Agg Files], NestOpt)
	onoff_files = UT.Expand(Args.[Transit OnOff Files], NestOpt)

    //Put all assignment files in an array so the processor can loop over modes.
    asn_files = {tflow_files, wflow_files, aflow_files, onoff_files}

    //Define output files
    dy_files = {Args.[Daily Transit Flow Files],
                Args.[Daily Transit Walk Files],
                Args.[Daily Transit Agg Files],
                Args.[Daily Transit OnOff Files]}

    asn_names = {"Transit Flows", "Transit Access/Egress Flows", "Aggregated Flows", "Boardings"}
    Periods  = {"EA", "AM", "MD", "PM", "EV"}
    Modes       = {"LOC", "PRM", "MIX"}   // List of transit modes
    AccessModes = {"WLK", "DRV", "KNR", "DRVE", "KNRE"}//Added for Transit Drive Egress AWalker Nov. 2016
    DriveAccessSource = 2 //index into AccessModes for drive, to use as table source

    //Aggregation settings for transit flows, walk flows, and the on/off table.
    //The loop below skips aggregated flows, since they do not combine correctly.
    //Define aggregation fields
    aggr_flds = {{"Route", "From_Stop", "To_Stop", "From_MP", "To_MP"},
                 {"ID1"},
                 {null},
                 {"STOP", "ROUTE"}}
    //Define output fields and aggregation rules
                 //Rules for transit flows
    out_flds = {{{"Route", "dominant"}, {"From_Stop", "dominant"}, {"To_Stop", "dominant"}, {"Centroid", "dominant"},
                 {"From_MP", "dominant"}, {"To_MP", "dominant"}, {"TransitFlow", "sum"}, {"BaseIVTT",  "average", "PMT"},
                 {"COST", "average", "PMT"}},

                //Rules for walk flows //smc 10-9-2014: Updated for TC6
               {{"ID1", "dominant"},
			    {"AB_NonTransitFlow", "sum"},
			    {"BA_NonTransitFlow", "sum"},
			    {"TOT_NonTransitFlow", "sum"},
			    {"AB_Access_Walk_Flow", "sum"},
                {"BA_Access_Walk_Flow", "sum"},
				{"AB_Xfer_Walk_Flow", "sum"},
				{"BA_Xfer_Walk_Flow", "sum"},
				{"AB_Egress_Walk_Flow", "sum"},
				{"BA_Egress_Walk_Flow", "sum"},

			    {"AB_Walk_Flow", "sum"}, //DACC only
			    {"BA_Walk_Flow", "sum"}, //DACC only

			    {"AB_Drive_Flow", "sum"},  //DACC only
			    {"BA_Drive_Flow", "sum"}}, //DACC only

                //Aggregated transit flows
                {null},

                //Rules for on/off tables
               {{"STOP", "dominant"}, {"ROUTE", "dominant"}, {"On", "sum"}, {"Off", "sum"}, {"WalkAccessOn", "sum"}, {"DirectTransferOn", "sum"},
                {"WalkTransferOn", "sum"}, {"DirectTransferOff", "sum"}, {"WalkTransferOff", "sum"}, {"EgressOff", "sum"},

                {"DriveAccessOn", "sum"}}}

    for asn_type = 1 to asn_files.length do
        //Skip the aggregated transit flows (asn_type = 3) - they can't be combined this way.

        if asn_type <> 3 then do

//EndStep
NextStep= "Combine Daily " + asn_names[asn_type]
SetStatus(1, NextStep, )


            //Create a temporary table
            // Use a drive access table, since some tables (e.g. walk flows)
            // have extra data for drive assignment.
            period = 1
            imode = 1
            iacc = DriveAccessSource
            vw_file = asn_files[asn_type][period][imode][iacc]
            t = SplitPath(vw_file)
            vw = OpenTable(t[3], "FFB", {vw_file})
            field_info = GetViewStructure(vw)
            union_file = GetTempFileName("*.bin")
            union_vw = CreateTable("Union", union_file, "FFB", field_info)

            CloseView(vw)


            //Add records from all assignment files to the union view
            CreateProgressBar("Combining...", "True")
            prog_tot = Periods.length * Modes.length * AccessModes.length
            prog_val = 0
            for period = 1 to Periods.length do
                for imode = 1 to Modes.length do
                    for iacc = 1 to AccessModes.length do
                        prog_pct = R2I(prog_val / prog_tot * 100)
                        prog_val = prog_val + 1
                        canned = UpdateProgressBar("Combining...", prog_pct)
                        if canned then do
                            DestroyProgressBar()
                            RunMacro("TCB Error", "Action Canceled by User")
                            Return(0)
                        end

                        vw_file = asn_files[asn_type][period][imode][iacc]
                        t = SplitPath(vw_file)
                        vw = OpenTable(t[3], "FFB", {vw_file})

                        //Read data from the assignment view
                        rec = GetFirstRecord(vw+"|",)
                        cnt = GetRecordCount(vw,)
                        asn_vals = GetRecordsValues(vw+"|", rec, null, null, cnt, "Row", )
                        field_names = GetFields(vw, "All")
                        field_names = field_names[1]

                        CloseView(vw)

                        //Write data (as new records) to the union table
                        AddRecords(union_vw, field_names, asn_vals, )
                    end //iacc
                end //imode
            end //period
            DestroyProgressBar()

            //Define aggregation of the table based on aggr_flds.  This creates an
            //expression with aggregation fields separated by underscores.
            expr = null
            for ii = 1 to aggr_flds[asn_type].length do
                expr = expr + "string("+aggr_flds[asn_type][ii]+")"
                if ii < aggr_flds[asn_type].length then do
                    expr = expr + " + \"_\" + "
                end
            end

            agg_fld = CreateExpression(union_vw, "AggregateBy", expr, )
            //Create a passenger miles traveled field to facilitate PMT weighted average baseIVTT and cost
            //THIS IS ONLY DONE FOR TRANSIT FLOWS
            if asn_type = 1 then do
                pmt_fld = CreateExpression(union_vw, "PMT", "if TransitFlow = 0 then 0.0001 else (TransitFlow * abs(TO_MP - FROM_MP))", )
            end

            dy_vw = AggregateTable("Peak Transit Flow", union_vw+"|", "FFB", dy_files[asn_type], agg_fld, out_flds[asn_type], {{"Missing Zero"}})

//EndStep
NextStep= "Adjust Aggregated Flow Field Names"
SetStatus(1, NextStep, )

            dy_info = GetTableStructure(dy_vw)
            dy_newinfo = null  //elements that are to be maintained are moved into dy_newinfo
            for ii = 1 to dy_info.length do
                //Drop the AggregateBy field
                if dy_info[ii][1] <> "AggregateBy" then do
                    //Add element 12, which is the original field name
                    dy_newinfo = dy_newinfo + {dy_info[ii] + {dy_info[ii][1]}}
                end
            end

            //Modify element 1, new field name to:
            //Remove "First " from applicable fields
            //Remove "Avg " from aplicable fields
            for ii = 1 to dy_newinfo.length do
                dy_newinfo[ii][1] = Substitute(dy_newinfo[ii][1], "First ", , )
                dy_newinfo[ii][1] = Substitute(dy_newinfo[ii][1], "Avg ", , )
            end

            ModifyTable(dy_vw, dy_newinfo)

            //Close views
            CloseView(union_vw)
            UT.Delete(union_file) //Delete temp union file
            CloseView(dy_vw)
        end //end if not aggregated transit flows
    end  //end loop over asn_typ

//EndStep
NextStep= "Aggregate Daily Flows"
SetStatus(1, NextStep, )

    //Load the route system in a map (for access to the stop layer)
    tdbd_info = GetDBInfo(tdbd_file)
    map_name = CreateMap("Route System", {{"Scope", tdbd_info[1]},{"Auto Project", "True"}})
    lyrs = AddRouteSystemLayer(map_name, "Route System", rts_file,)
    RunMacro("Set Default RS Style", lyrs, "TRUE", "TRUE")
    route_lyr = lyrs[1]
    stop_lyr  = lyrs[2]
    stop_file = GetLayerDB(stop_lyr)
    lyrs = RunMacro("TCB get DB line and node layers", tdbd_file)
    tnode_lyr = lyrs[1]
    tlink_lyr = lyrs[2]
    lyrs = null

    dy_vw = OpenTable("TransitFlows", "FFB", {dy_files[1]})
    dy_lyr = AddLRSLayer(map_name, "Transit Flows", {dy_vw, "Line", "ROUTE", "FROM_MP", "TO_MP"}, route_lyr)
    CloseView(dy_vw)
    RunMacro("G30 new layer default settings", dy_lyr)
    //SetOffset(dy_lyr + "|", "Channel", 0)
    //SetLineStyle(dy_lyr + "|", d_linestyles[69])

    agg_file = GetTempFileName(".bin")
    SplitLRSLayer(dy_lyr, agg_file, "FFB", {"TransitFlow"}, null)
    agg_vw = OpenTable("Agg1", "FFB", {agg_file})
    outflds = {{  "TransitFlow", "SQ"},
               {"ABTransitFlow", "SQ"},
               {"BATransitFlow", "SQ"}}
    CleanMilepostView(dy_files[3], "FFB", agg_vw + "|", "ROUTE", "FROM_MP",
                      "TO_MP", outflds, {{"missing as zero"}})

    //Close the Map
    SetMapSaveFlag(map_name, "False")
    CloseMap(map_name)

    //Close and delete the agg file
    CloseView(agg_vw)
    UT.Delete(agg_file)

//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
    RunMacro("G30 File Close All")
    Return(1)
//EndStep
EndMacro



Macro "Add P and A Vectors" (Tab1, Tab2, FieldList)

    view1 = RunMacro("TCB OpenTable",,, {Tab1})
    view2 = RunMacro("TCB OpenTable",,, {Tab2})
    ok = (view1 <> null & view2 <> null)
    if !ok then goto exit

    for field = 1 to FieldList.length do
        v1 = GetDataVector(view1 + "|", FieldList[field],)
        v2 = GetDataVector(view2 + "|", FieldList[field],)
        v1 = v1 + v2
        SetDataVector( view1 + "|", FieldList[field], v1,)
    end

    CloseView(view1)
    CloseView(view2)

    exit:
    return(ok)
EndMacro


// Creates a matrix that contain the Parking Lot ID instead of the ZoneID
// used to assign PR od matrices without the car portion (on the regular network)
Macro "OD to Park" (OD_mc_info, park_mat, out_mat_f, park_at, Args)

    db_file = Args.[Highway DB]
    {node_lyr,} = RunMacro("TCB Add DB Layers", db_file)
    ok = (node_lyr <> null)     if !ok then goto exit
    db_nodeLyr = db_file + "|" + node_lyr

    {od_mat, od_core, od_ridx, od_cidx} = OD_mc_info
    od_m = RunMacro("TCB OpenMatrix", od_mat,)
    ok = (od_m <> null)  if !ok then goto exit
    if od_m = null then
        return(False)
    od_mc = CreateMatrixCurrency(od_m, od_core, od_ridx, od_cidx,)
    park_m = RunMacro("TCB OpenMatrix", park_mat,)
    ok = (park_m <> null)  if !ok then goto exit
    if od_m = null then
        return(False)
    park_mc = CreateMatrixCurrency(park_m, "Parking Nodes", "RCIndex", "RCIndex",)  // default index is node-id

        // create intermediate od matrix containing trips for od-pairs whose paths use parking
    mat_f = RunMacro("Get Temp File Name", "*.mtx")
    SetInfo = {db_nodeLyr, node_lyr, "Centroids", "Select * Where Centroid <> null"}
    Arguments = {mat_f,, {"Park Node", "Trips"}, {"Float"}, {SetInfo, "ID", "RCIdx"}, }
    ok = RunMacro("TCB Create Matrix", Arguments)
    if !ok then goto exit

    mat = RunMacro("TCB OpenMatrix", mat_f,)
    ok = (mat <> null)  if !ok then goto exit
    {,col_idx} = GetMatrixIndex(mat)
    park_node_mc = CreateMatrixCurrency(mat, "Park Node",,,)
    trip_mc = CreateMatrixCurrency(mat, "Trips",,,)

    park_node_mc := park_mc
    trip_mc := if park_node_mc <> null then od_mc else null

        // output intermediate od matrix to table
    tb_n = GetTempFileName("*.bin")
    CreateTableFromMatrix(mat, tb_n, "FFB", )
    view = OpenTableEx("TView", "FFB", {tb_n}, {{"Shared", "False"}})

    opts.[File Name] = out_mat_f
    opts.[Type] = "Float"
    opts.[Sparse]= "No"
    opts.[Column Major]= "No"
    opts.[File Based]="Yes"

    if Upper(park_at) = "ROW" then
        do
		row_id = "[Park Node]"
		col_id = "RCIdx"
	end
    else
        do
//		row_id = "RCIdx"
		row_id = "RCIdx:1" 		//corrected cjl122008
		col_id = "[Park Node]"
	end
    m = CreateMatrixFromView("PR OD", view + "|", row_id, col_id, {"Trips"}, opts)
    mc = CreateMatrixCurrency(m, "Trips",,,)
    mc := null

    update_flds = {view + ".Trips"}
    UpdateMatrixFromView(m, view + "|", row_id, col_id,, update_flds, "Add", {{"Missing is zero", "Yes"}})

    exit:
    if view <> null then
        CloseView(view)
    return(ok)
EndMacro


Macro "Get Temp File Name" (fname)
    file_name = GetTempFileName(fname)
    fp = OpenFile(file_name, "a")    // Make sure the file exist so that an additional call to TempFile will give a different file
    CloseFile(fp)
    return(file_name)
EndMacro

// convert from highway link speed to transit link time and assign to IVTT fields  cjl012009
Macro "Update IVTT Fields" (ArgArr)
    {Periods, vw_set, dir, tran_lkup_sets, LookUpFlds, dist, fc, cng_spd, initial} = ArgArr

    for k = 1 to tran_lkup_sets do      // for each transit link time loopup set
        kk = i2s(k)
        to_convert = (ArrayPosition(LookUpFlds, {"CutOff_"  + kk},) > 0) // = 1 if conversion is necessary for current set
        if to_convert then do
            cutoff   = GetDataVector(vw_set, "CutOff_"  + kk,)
            low_tran = GetDataVector(vw_set, "LowTran_" + kk,)
            slopeH   = GetDataVector(vw_set, "SlopeH_"  + kk,)
            slopeL   = GetDataVector(vw_set, "SlopeL_"  + kk,)
          end

        trn_spd =   if fc >= 90  | cng_spd = null | cng_spd <= 0 then    // if connectors or bad highway speed
                        null
                    else if (fc > 80 & fc < 90)  | (!to_convert) then
                        cng_spd
                    else if cng_spd < cutoff then
                        cng_spd - (cng_spd * slopeH)
                    else
                        (cng_spd - cutoff) * slopeL + low_tran
        trn_time =  if trn_spd <> null then     // if new transit speed calculated
                        max(0.0001, dist / trn_spd * 60)
                    else
                        null
            // currently duplicate IVTT for all time periods
        if initial then do                  // if doing intialization
            for j = 1 to Periods.length do
 //               time_fld = dir + "_" + Periods[j] + "_IVTT_" + kk
                time_fld = dir + Periods[j] + "_IVTT_" + kk	//bug fixed
                SetDataVector(vw_set, time_fld, trn_time,)
              end
          end
        else do                             // if updating after assisgnment
            for j = 1 to Periods.length do
 //               time_fld = dir + "_" + Periods[j] + "_IVTT_" + kk
                 time_fld = dir + Periods[j] + "_IVTT_" + kk 	//bug fixed
                curr_trn_time = GetDataVector(vw_set, time_fld,)   // get current transit link time
                trn_time =  if trn_time <> null then trn_time else curr_trn_time    // if no new transit link time then no updating
                SetDataVector(vw_set, time_fld, trn_time,)
              end
          end
      end // for k
EndMacro


// update highway
Macro "Update Link Times" (Args, period)
        // Inputs
    db_file = Args.[Highway DB]
    net_file = Args.[Network File]
    spd_cap_tb = Args.[Speed Capacity Table]

    {, link_lyr} = RunMacro("TCB Add DB Layers", db_file)
    ok = (link_lyr <> null) if !ok then goto exit
    spd_cap_vw = RunMacro("TCB OpenTable",,, {spd_cap_tb})
    ok = (spd_cap_vw <> null)  if !ok then goto exit
    {LookUpFlds,} = GetFields(spd_cap_vw, "Numeric")	//cjl012009
    net = ReadNetwork(net_file)

        // dump congested network link times to temp. file
    h_time_fld = period + "_HwyT"
    h_cost_fld = period + "_HwyC"
//    t_time_fld = period + "_IVTT"		//cjl012009
    cng_cost_fld = "MSA_COST_" + period
    cng_time_fld = "MSA_TIME_" + period
	  ivtt_time = period + "_IVTT_1"

    temp_file = GetTempFileName(GetTempPath() + "*.bIN")
    Opts = null
    Opts.[Flow Fields] = {cng_cost_fld, cng_time_fld}           // congested cost & time fields to write
    Opts.[Write To] = {temp_file, "FFB", period + " Congested Time"}
    net_fld_vw = CreateTableFromNetworkVars(net, Opts)
        // join link layer, congested time view, and lookup view
    jvw1 = JoinViews("j1", link_lyr + ".ID",  net_fld_vw + ".ID1", )
    key1 = CreateExpression(jvw1, "key1", "String(AREA_TYPE) + \" \" + String(NFC) + \" \" + NFC_Flag", {{"Type", "String"}})	//Updated the function class by JChen in August 2015
    key2 = CreateExpression(spd_cap_vw, "key2", "String(AT) + \" \" + String(NFC_N) + \" \" + SFlag", {{"Type", "String"}})	//Updated the function class by JChen in August 2015
    jvw2 = JoinViews("j2", jvw1+"."+key1, spd_cap_vw+"."+key2,)   // join to lookup table
    vw_set = jvw2 + "|"
    CloseView(jvw1)
    CloseView(net_fld_vw)

    SetStatus(2, "Reading variables for updating link times",)
    //========================================================
    dist = GetDataVector(vw_set, "Length",)
    fc = GetDataVector(vw_set, "NFC",)	//Updated the function class by JChen in August 2015
    tran_lkup_sets = 2
    Dir = {"AB_", "BA_"}
    for i = 1 to 2 do
        dir = Dir[i]
        SetStatus(2, "Updating highway link times (" + dir + "direction)",)
        //=================================================================
        cng_cost = GetDataVector(vw_set, dir + cng_cost_fld,)
        SetDataVector(vw_set, dir + h_cost_fld, cng_cost,)
        cng_time = GetDataVector(vw_set, dir + cng_time_fld,)
        SetDataVector(vw_set, dir + h_time_fld, cng_time,)
        ivtt_ini_time = GetDataVector(vw_set, dir + ivtt_time,)	//updated by J. Chen on Feb. 23, 2013


		//  jcl_05_02_2011 - fill line layer with transit IVTT time - remark call to macro Update IVTT Fields
		    trn_time = if (fc > 80 and fc < 90) then ivtt_ini_time else cng_time * 0.917	//updated by J. Chen on Feb. 23, 2013
  	//		trn_time = cng_time * 0.917
        SetDataVector(vw_set, dir + ivtt_time, trn_time,)

  // PB Addition (July 19, 2013) - Added IVTT_3 field which gets IVTT_1 (if link is shared) or IVTT_2 if link is exclusive




        	    Opts.Input.[Dataview Set] = {db_file+"|Network", "Network", "Selection", "Select * Where TransitOnly = 0"}
              Opts.Global.Fields = {dir+period+"_IVTT_3"}
              Opts.Global.Method = "Formula"
              Opts.Global.Parameter = {dir+period+"_IVTT_1"}
              Opts.Flag.[Post Process] = "True"

              ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)



// end addition

        //SetStatus(2, "Converting to tranit link times (" + dir + "direction)",)
        //=====================================================================
        //cng_spd = if cng_time > 0 then dist / cng_time * 60  else null
        //ArgArr = {{period}, vw_set, dir, tran_lkup_sets, LookUpFlds, dist, fc, cng_spd, 0}		//cjl012009
        //RunMacro("Update IVTT Fields", ArgArr)

	end
    CloseView(jvw2)

    exit:
    return(ok)
EndMacro


// add matrix index mapping node id to zone id
Macro "Add Matrix Zone ID Index" (mat_file, Args)
    highway_db = Args.[Highway DB]
    {node_lyr,} = RunMacro("TCB Add DB Layers", highway_db)
    ok = (node_lyr <> null)     if !ok then goto exit
    db_nodeLyr = highway_db + "|" + node_lyr

    input_mtx = OpenMatrix(mat_file, )
    matrix_indices = GetMatrixIndexNames(input_mtx)
  	for i=1 to matrix_indices[1].length do
    	if matrix_indices[1][i]="ZoneID" then DeleteMatrixIndex(input_mtx, "ZoneID")
	end

    Opts = {{"Input",   {{"Current Matrix",    mat_file},
                         {"Index Type",        "Both"},
                         {"View Set",          {db_nodeLyr, node_lyr, "Centroids", "Select * where Centroid <> null"}},
                         {"Old ID Field",      {db_nodeLyr, "ID"}},
                         {"New ID Field",      {db_nodeLyr, "Centroid"}}}},
            {"Output",  {{"New Index",         "ZoneID"}}}}
    ok = RunMacro("TCB Run Operation", 1, "Add Matrix Index", Opts)

    input_mtx = null
    exit:
    return(ok)
EndMacro

// add matrix index mapping zone id to node id
Macro "Add Matrix Node ID Index" (mat_file, Args)
    highway_db = Args.[Highway DB]
    {node_lyr,} = RunMacro("TCB Add DB Layers", highway_db)
    ok = (node_lyr <> null)     if !ok then goto exit
    db_nodeLyr = highway_db + "|" + node_lyr

    input_mtx = OpenMatrix(mat_file, )
	matrix_indices = GetMatrixIndexNames(input_mtx)
	for i=1 to matrix_indices[1].length do
		if matrix_indices[1][i]="NodeID" then DeleteMatrixIndex(input_mtx, "NodeID")
	end

    Opts = {{"Input",   {{"Current Matrix",    mat_file},
                         {"Index Type",        "Both"},
                         {"View Set",          {db_nodeLyr, node_lyr, "Centroids", "Select * where Centroid <> null"}},
                         {"Old ID Field",      {db_nodeLyr, "Centroid"}},
                         {"New ID Field",      {db_nodeLyr, "ID"}}}},
            {"Output",  {{"New Index",         "NodeID"}}}}
    ok = RunMacro("TCB Run Operation", 1, "Add Matrix Index", Opts)
    input_mtx = null
    exit:
    return(ok)
EndMacro

Macro "SEMCOG Add Matrix Cores" (mat, Cores)
    on error goto next
    for i=1 to Cores.length do
       AddMatrixCore(mat, Cores[i])
       next:
       end
    on error default
EndMacro


/*-----------**
** UTILITIES **
**-----------*/

dbox "SEMCOG Utilities" (ScenSel, ScenArr)
    title: "SEMCOG Utility Dbox"
    Init do
        shared  util_idx, Scen, UT

        UtilList = {"Remove Progress Bar",
                    "Save Feedback Speeds",
                    "Update Area Type",
					"Count VMT Tool"}

        TCBFlag = {0, 0, 0, 0}     // Only run TCB init/close if true

        if util_idx = null then
            util_idx = 1

        ArgArr = Scen.Arr[Scen.Vars.ScenFlag[1]][2]
        Args = Scen.Control.Simplified(ArgArr)

    enditem

    popdown menu 12, 0.5, 30, 6 prompt: "Utility Macros"  list: UtilList  variable: util_idx

    button "OK" 45, 0.5, 10 do
        util_name = "SEMCOG " + UtilList[util_idx]
        if TCBFlag[util_idx] then do
            RunMacro("TCB Init")

            HideDbox()
            ok = RunMacro(util_name, Args)
            ShowDbox()

            RunMacro("TCB Closing", ok, True )
        end
        else do
            HideDbox()
            ok = RunMacro(util_name, Args)
            ShowDbox()
        end
        Return(ok)
        endItem
    button "Cancel"  Same, 2, 10  cancel do Return() endItem
EndDbox

Macro "SEMCOG Remove Progress Bar"
    on error goto exit
    on notfound goto exit
    DestroyProgressBar()
    exit:
    return(1)
EndMacro

Macro "SEMCOG Save Feedback Speeds" (Args)

    //Confirm operation
    msg = "This utility will update the input network with default speeds based " +
          "on results of the most recently completed speed feedback model run.  \n\n" +
          "Any open files will be closed.\n\n" +
          "Continue?"
    ans = MessageBox(msg, {"Caption":"Update Feedback Speeds?", "Buttons":"YesNo", "Default":2})
    if ans != "Yes" then Return()

    //Close any open files, don't ask the user since they already confirmed
    {maps,,} = GetMaps()
    if maps != null then do
        for m in maps do
            SetMapSaveFlag(m, "False")
        end

    end
    RunMacro("G30 File Close All")

    //Open the network file
    dbd_file = Args.[Highway DB]
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", dbd_file)


    //Period and direction prefix for loops
    dirs = {"AB", "BA"}
    pers = Args.HwyPeriods
    prefix = {"AB_AM", "BA_AM", "AB_MD", "BA_MD"}

    //Load feedback results
    for d in dirs do
        for p in pers do
            pfx = d+"_"+p
            GetFlds = GetFlds + {pfx+"_HwyS"}
        end
    end
    Vs = GetDataVectors(link_lyr+"|", GetFlds, )

    //Set Feedback defaults
    SetVs = null
    ii  =1
    for d in dirs do
        for p in pers do
            pfx = d+"_"+p
            SetVs.(pfx+"FB") = Vs[ii]
            ii = ii + 1
        end
    end
    SetDataVectors(link_lyr+"|", SetVs, )

    Return(1)

EndMacro

Macro "SEMCOG Update Area Type" (Args)

    shared Scen

    SetAlternateInterface(Scen.Vars.interop_file)
    RunDbox("Area Type", Args)
    SetAlternateInterface()
EndMacro

Macro "SEMCOG Count VMT Tool" (Args)
    RunDbox("SEMCOG Count VMT Tool", Args)
EndMacro

Dbox "SEMCOG Count VMT Tool" (Args)

    init do

        shared UT, Scen

        //Set Default filenames
        Opts = null
        Opts.[Highway DB] = Args.[Highway DB]
        Opts.[DY Highway Flows] = Args.[DY Highway Flows]
        Opts.[Count Table] = Args.[Count Table]

        t = SplitPath(Opts.[Highway DB])
        Opts.[Annual Counts] = t[1]+t[2]+"COUNTS_00_to_16.DBF"

        t = SplitPath(Args.[Summary Report])
        Opts.[VMT Output] = t[1]+t[2]+"VMT_Trends.bin"

        //Create the grid object
        SetLibrary(Scen.Vars.utilui_file)
        GV = CreateObject("FileGrid", Opts)
        SetLibrary()

    enditem

    grid view 1, 1, 100, 15 Columns: GV.grid_cols List: GV.FileList variables: cell_idx, cell_chg Editable resize: width, height do
        GV.Click(cell_idx, cell_chg)
    enditem

    Button "Calculate" 80, 18, 10, 1.5 do
        RunMacro("VMT Adjust", Opts.[Count Table], Opts.[Annual Counts], Opts.[Highway DB], Opts.[DY Highway Flows], Opts.[VMT Output])
        Return()
    enditem

    Button "Cancel" after, same, 10, 1.5 do
        Return()
    enditem



EndDbox

Macro "VMT Adjust" (val_counts, count_file, dbd_file, flow_file, out_file)

RunMacro("TCB Init")

NextStep= "Load Geographic File and Open Relevant Tables"

    //load dbd network
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", dbd_file,,)

	//Open count tables
	val_vw = OpenTable("Validation Counts", "FFB", {val_counts})
	count_vw = OpenTable("Available Counts", "DBASE", {count_file})

	//Open flow file and join to network
	flow_vw = OpenTable("Assignment", "FFB", {flow_file})
	join_vw = JoinViews("Network + Assignment", link_lyr+".ID", flow_vw+".ID1", )

    //Detect VMT field
    {flow_flds, } = GetFields(flow_vw, "All")
    if flow_flds contains "TOT_VMT" then vmt_fld = "TOT_VMT"
    else vmt_fld = "TOT_V_Dist_T"

	//Set up output files
	out_fields = {{"Modeled VMT", "Real", 16, 4, "True", , , , , , , null},
	              {"Count VMT", "Real", 16, 4, "True", , , , , , , null},
                  {"Modeled VMT on Links with Counts", "Real", 16, 4, "True", , , , , , , null},
                  {"Scale Factor", "Real", 16, 4, "True", , , , , , , null},
				  {"Adjusted VMT", "Real", 16, 4, "True", , , , , , , null},
				  {"Number of Counts", "Integer", 16, null, "True"}}

	temp_file = GetTempFileName(".bin")
	temp_vw = CreateTable("County VMT", temp_file, "MEM", {{"County", "Short", 16, null, "Yes"}} + out_fields) // by county
	temp_file2 = GetTempFileName(".bin")
	temp_vw2 = CreateTable("FTYPE VMT", temp_file2, "MEM", {{"FTYPE", "Integer", 16, null, "Yes"}} + out_fields) // by facility type

//EndStep
NextStep= "Calculate Modeled VMT by County"

	//Calculate modeled VMT totals by county and by facility type
	//County
	Agg = {{vmt_fld, "sum"}}
	agg_county_vw = AggregateTable("VMTAgg", join_vw+"|", "MEM", "VMTAgg.bin", "COUNTY", Agg, )
	SetView(agg_county_vw)
	county_incl = SelectByQuery("COUNTY", "Several", "Select * where COUNTY < 9",) //exclude external county
    County_Vs = GetDataVectors(agg_county_vw+"|COUNTY", {"COUNTY", vmt_fld}, {{"Return Options Array", "True"},{"Sort Order", {{"COUNTY", "Ascending"}}}})

	//Read county-level VMT into vector
	FACCOUNTY_VOL = null
	for II = 1 to County_Vs.COUNTY.length do
        tmp = County_Vs.(vmt_fld)
        FACCOUNTY_VOL.(i2s(County_Vs.COUNTY[II])).(vmt_fld) = tmp[II]
    end

	//Populate output file with county and modeled VMT information
	SetVs = {{temp_vw+".County", County_Vs.COUNTY},
             {temp_vw+".Modeled VMT", County_Vs.(vmt_fld)}}

//EndStep
NextStep= "Calculate Modeled VMT by Facility Type"

	CreateExpression(join_vw, "FTYPE", 'if Left(NFC_FLAG,1) = "R" then 11 else if NFC_FLAG = "FCD" then 12 else NFC', {{"Type", "Integer"}})

	//Facility type
	agg_ft_vw = AggregateTable("VMTAgg", join_vw+"|", "MEM", "VMTAgg.bin", "FTYPE", Agg, )
	SetView(agg_ft_vw)
	ft_incl = SelectByQuery("FTYPE", "Several", "Select * where FTYPE <> 90",) //exclude ftype =90
	FT_Vs = GetDataVectors(agg_ft_vw+"|FTYPE", {"FTYPE", vmt_fld}, {{"Return Options Array", "True"}, {"Sort Order", {{"FTYPE", "Ascending"}}}})

	//Read ftype-level VMT into vector
	FACFT_VOL = null
    for II = 1 to FT_Vs.FTYPE.length do
        tmp = FT_Vs.(vmt_fld)
        FACFT_VOL.(i2s(FT_Vs.FTYPE[II])).(vmt_fld) = tmp[II]
    end

	//Populate output file with ftype and modeled VMT information
	SetVs_ft = {{temp_vw2+".FTYPE", FT_Vs.FTYPE},
             {temp_vw2+".Modeled VMT", FT_Vs.(vmt_fld)}}

//EndStep
NextStep= "Read Validation Counts and Adjust County VMT"

	//Join validation counts
	join_vw2 = JoinViews("Network + Validation Counts", join_vw+".ID", val_vw+".ID", )

	//Add fields
	CreateExpression(join_vw2, "Base_Year_Count_Avail", 'if DAILY > 0 then 1 else 0',	{{"Type", "Integer"}})
	CreateExpression(join_vw2, "Count_VMT", 'DAILY * length', {{"Type", "Real"}})

	//Aggregate for links with validation counts
	//County
	SetView(join_vw2)
	base_count = SelectByQuery("BaseCounts", "Several", "Select * where Base_Year_Count_Avail = 1",)
	Agg = {{vmt_fld, "sum"}, {"Count_VMT", "sum"}}
    agg_county_vw = AggregateTable("VMTAgg", join_vw2+"|BaseCounts", "MEM", "VMTAgg.bin", "COUNTY", Agg, ) //aggregate by county
	County_count_Vs = GetDataVectors(agg_county_vw+"|", {"COUNTY", vmt_fld, "Count_VMT"}, {{"Return Options Array", "True"}, {"Sort Order", {{"COUNTY", "Ascending"}}}})
	Agg_County = {{"COUNTY", "count"}}
	agg_count = AggregateTable("CountAgg", join_vw2+"|BaseCounts", "MEM", "CountAgg.bin", "COUNTY", Agg_County, ) //count by county
	count_Vs = GetDataVector(agg_count+"|", "[N COUNTY]", {{"Return Options Array", "True"}, {"Sort Order", {{"COUNTY", "Ascending"}}}}) // get number of counts by county


	//Read county-level count and model VMT on links with validation counts into vectors
	FACCOUNTY_COUNT_COUNT = null
	FACCOUNTY_COUNT_VOL = null
	FACCOUNTY_COUNT = null

	for II = 1 to County_count_Vs.COUNTY.length do
        tmp = County_count_Vs.[Count_VMT]
        FACCOUNTY_COUNT_COUNT.(i2s(County_count_Vs.COUNTY[II])).[Count_VMT] = tmp[II]
		tmp_vol = County_count_Vs.(vmt_fld)
		FACCOUNTY_COUNT_VOL.(i2s(County_count_Vs.COUNTY[II])).(vmt_fld) = tmp_vol[II]
		tmp_count = count_Vs
		FACCOUNTY_COUNT.(i2s(County_count_Vs.COUNTY[II])).[COUNT] = tmp_count[II]
    end

	//Initialize arrays
	dim county_count_vmt[County_Vs.COUNTY.length]
	dim county_model_vmt[County_Vs.COUNTY.length]
	dim county_scale_fac[County_Vs.COUNTY.length]
	dim county_count[County_Vs.COUNTY.length]

	//Calculate scale factor
	dim baseyr_vmt_county[County_Vs.COUNTY.length]
	for II = 1 to County_Vs.COUNTY.length do
	    if nz(FACCOUNTY_COUNT_COUNT.(i2s(County_Vs.COUNTY[II])).[Count_VMT]) = 0 then do
		    scale_fac = 1 // if no county counts exist
		end
		else do
		    baseyr_vmt_count_county = FACCOUNTY_COUNT_VOL.(i2s(County_Vs.COUNTY[II])).(vmt_fld)
			county_model_vmt[II] = baseyr_vmt_count_county // populate array
	        count_vmt_count_county = FACCOUNTY_COUNT_COUNT.(i2s(County_Vs.COUNTY[II])).[Count_VMT]
			county_count_vmt[II] = count_vmt_count_county // populate array
		    scale_fac = count_vmt_count_county / baseyr_vmt_count_county // scale factor is the ratio of count VMT to model VMT on links with validation counts
		end

		if nz(FACCOUNTY_COUNT.(i2s(County_Vs.COUNTY[II])).[COUNT]) = 0 then do
		    county_count[II] = 0
		end
		else do
		    county_count[II] = nz(FACCOUNTY_COUNT.(i2s(County_Vs.COUNTY[II])).[COUNT])
		end

		county_scale_fac[II] = scale_fac // populate array

		baseyr_vmt_county[II] = nz(FACCOUNTY_VOL.(i2s(County_Vs.COUNTY[II])).(vmt_fld)) * scale_fac // adjusted VMT is the base VMT multiplied by the scale factor
	end

    baseyr_adjusted_county_total = VectorStatistic(A2V(baseyr_vmt_county), "Sum", )	// total adjusted VMT is the total of the county-specific adjusted VMT

	rh = AddRecords(temp_vw, null, null, {{"Empty Records", County_Vs.COUNTY.length}}) // add empty records

	//Populate output file with count vmt, scale factor and adjusted vmt at the county level
	SetVs = SetVs + {{temp_vw+".Modeled VMT on Links with Counts", A2V(county_model_vmt)},
	         {temp_vw+".Count VMT", A2V(county_count_vmt)},
             {temp_vw+".Scale Factor", A2V(county_scale_fac)},
			 {temp_vw+".Adjusted VMT", A2V(baseyr_vmt_county)},
			 {temp_vw+".Number of Counts", A2V(county_count)}}

	SetDataVectors(temp_vw+"|", SetVs, ) // Update temp view with county-level data

	t = SplitPath(out_file)
	county_table = t[1] + t[2] + "CountyTableVMT.csv"
	ExportView(temp_vw+"|", "CSV", county_table, null, {{"CSV Header", "True"}}) // write temp view to csv file
	CloseView(temp_vw)


//EndStep
NextStep= "Adjust FTYPE VMT"

	//Facility type
	agg_ft_vw = AggregateTable("VMTAgg", join_vw2+"|BaseCounts", "MEM", "VMTAgg.bin", "FTYPE", Agg, ) //aggregate by functional class
	SetView(agg_ft_vw)
	FT_count_Vs = GetDataVectors(agg_ft_vw+"|", {"FTYPE", vmt_fld, "Count_VMT"}, {{"Return Options Array", "True"}, {"Sort Order", {{"FTYPE", "Ascending"}}}})
	Agg_ft = {{"FTYPE", "count"}}
	agg_count = AggregateTable("CountAgg", join_vw2+"|BaseCounts", "MEM", "CountAgg.bin", "FTYPE", Agg_ft, ) //count by county
	count_Vs = GetDataVector(agg_count+"|", "[N FTYPE]", {{"Return Options Array", "True"}, {"Sort Order", {{"FTYPE", "Ascending"}}}}) // get number of counts by county

	//Read ftype-level count and model VMT on links with validation counts into vectors
	FACFT_COUNT_COUNT = null
	FACFT_COUNT_VOL = null
	FACFT_COUNT = null

	for II = 1 to FT_count_Vs.FTYPE.length do
        tmp = FT_count_Vs.[Count_VMT]
        FACFT_COUNT_COUNT.(i2s(FT_count_Vs.FTYPE[II])).[Count_VMT] = tmp[II]
		tmp_vol = FT_count_Vs.(vmt_fld)
		FACFT_COUNT_VOL.(i2s(FT_count_Vs.FTYPE[II])).(vmt_fld) = tmp_vol[II]
		tmp_count = count_Vs
		FACFT_COUNT.(i2s(FT_count_Vs.FTYPE[II])).[COUNT] = tmp_count[II]
    end

	//Initialize arrays
	dim ft_count_vmt[FT_Vs.FTYPE.length]
	dim ft_model_vmt[FT_Vs.FTYPE.length]
	dim ft_scale_fac[FT_Vs.FTYPE.length]
	dim ft_count[FT_Vs.FTYPE.length]

	//Calculate scale factor
	dim baseyr_vmt_ft[FT_Vs.FTYPE.length]
	for II = 1 to FT_Vs.FTYPE.length do
	    if nz(FACFT_COUNT_COUNT.(i2s(FT_Vs.FTYPE[II])).[Count_VMT]) = 0 then do
		    scale_fac = 1 // if no ftype counts exist
		end
		else do
		    baseyr_vmt_count_ft = FACFT_COUNT_VOL.(i2s(FT_Vs.FTYPE[II])).(vmt_fld)
			ft_model_vmt[II] = baseyr_vmt_count_ft // populate array
	        count_vmt_count_ft = FACFT_COUNT_COUNT.(i2s(FT_Vs.FTYPE[II])).[Count_VMT]
			ft_count_vmt[II] = count_vmt_count_ft // populate array
		    scale_fac = count_vmt_count_ft / baseyr_vmt_count_ft // scale factor is the ratio of count VMT to model VMT on links with validation counts
		end

		if nz(FACFT_COUNT.(i2s(FT_Vs.FTYPE[II])).[COUNT]) = 0 then do
		    ft_count[II] = 0
		end
		else do
		    ft_count[II] = nz(FACFT_COUNT.(i2s(FT_Vs.FTYPE[II])).[COUNT])
		end

		ft_scale_fac[II] = scale_fac // populate array

		baseyr_vmt_ft[II] = nz(FACFT_VOL.(i2s(FT_Vs.FTYPE[II])).(vmt_fld)) * scale_fac // adjusted VMT is the base VMT multiplied by the scale factor
	end

    baseyr_adjusted_ft_total = VectorStatistic(A2V(baseyr_vmt_ft), "Sum", ) // total adjusted VMT is the total of the ftype-specific adjusted VMT

	rh = AddRecords(temp_vw2, null, null, {{"Empty Records", FT_Vs.FTYPE.length}})

	//Populate output file with count vmt, scale factor and adjusted vmt at the county level
	SetVs_ft = SetVs_ft + {{temp_vw2+".Modeled VMT on Links with Counts", nz(A2V(ft_model_vmt))},
	         {temp_vw2+".Count VMT", nz(A2V(ft_count_vmt))},
             {temp_vw2+".Scale Factor", nz(A2V(ft_scale_fac))},
			 {temp_vw2+".Adjusted VMT", nz(A2V(baseyr_vmt_ft))},
			 {temp_vw2+".Number of Counts", nz(A2V(ft_count))}}

	SetDataVectors(temp_vw2+"|", SetVs_ft, ) // Update temp view 2 with ft-level data

	t = SplitPath(out_file)
	ft_table = t[1] + t[2] + "FTTableVMT.csv"
	ExportView(temp_vw2+"|", "CSV", ft_table, null, {{"CSV Header", "True"}}) // write temp view to csv file
	CloseView(temp_vw2)


//EndStep
NextStep= "Calculate Average Adjusted VMT"

	baseyr_adjusted_vmt = (baseyr_adjusted_county_total + baseyr_adjusted_ft_total) / 2 // adjusted VMT is the average of the county and ftype adjusted VMT

//EndStep
NextStep= "Write base outputs to output file"

	out_fields = {{"Year", "Integer", 10, 0},
	              {"Validation Count VMT on Common Links", "Real", 20, 5},
				  {"Other Count VMT on Common Links", "Real", 20, 5},
				  {"Growth Factor", "Real", 20, 5},
				  {"Adjusted VMT - Method 2", "Real", 20, 5},
				  {"NumCommonLinksWithCounts - Method 2", "Integer", 10, 0},
				  {"Adjusted VMT - Method 1", "Real", 20, 5},
				  {"NumLinksWithOtherCounts - Method 1", "Integer", 10, 0}}

	vmt_vw = CreateTable("CalculatedVMT", out_file, "FFB", out_fields)
	rh = AddRecord(vmt_vw, {{"Year", "2015"}, {"Adjusted VMT - Method 2", baseyr_adjusted_vmt}}) // write adjusted base VMT to file

//EndStep
NextStep= "Get years of available counts"

	//Understand available counts
	count_flds = GetFields(count_vw, )
	aadt_fields = null
	awdt_fields = null
	years = null

	//Get AADT and AWDT fields
	for field in count_flds[1] do
	   if Left(field, 4) = "AADT" then do
	       aadt_fields = aadt_fields + {field}
		end
		if Left(field, 4) = "AWDT" then do
		    awdt_fields = awdt_fields + {field}
		end
	end

	//Get years
	for field in awdt_fields do
	    if PositionFrom(1,Right(field,2),"_") = 1 then do
		    years = years + {JoinStrings({"200", Right(field,1)},)}
		end
		else years = years + {JoinStrings({"20", Right(field,2)},)}
	end

//EndStep
NextStep= "Join to Network and Validation counts and get common link stats"

	join_vw3 = JoinViews("Network + Validation Counts + Avail Counts", join_vw2+"."+link_lyr+".ID", count_vw+".ID", )

    for _yr = 1 to years.length do
		// Calculate totals for common links
		SetView(join_vw3)
	    common_count = SelectByQuery("Common", "Several", "Select * where DAILY > 0 and " + awdt_fields[_yr] + " > 0",)
		CreateExpression(join_vw3, awdt_fields[_yr] + "_VMT", awdt_fields[_yr] + '* length', {{"Type", "Real"}})
		{other_VMT, count_VMT} = GetDataVectors(join_vw3+"|Common", {awdt_fields[_yr] + "_VMT", "Count_VMT"}, )

		//Calculate growth factor
	    gf_year = VectorStatistic(other_VMT, "Sum", ) / VectorStatistic(count_VMT, "Sum", ) // growth factor for year

		rh = AddRecord(vmt_vw, {{"Year", years[_yr]}, {"Validation Count VMT on Common Links", VectorStatistic(count_VMT, "Sum", )}, {"NumCommonLinksWithCounts - Method 2", common_count}, {"Growth Factor", gf_year}, {"Other Count VMT on Common Links", VectorStatistic(other_VMT, "Sum", )}, {"Adjusted VMT - Method 2", baseyr_adjusted_vmt * gf_year}}) //forecast or backcast year VMT = adjusted base year VMT * growth factor
	end

	CloseView(join_vw3)
	CloseView(join_vw2)

//EndStep
NextStep= "Calculate adjusted VMT for other years using the first method"

	//Join Network + Flows to other count table
	join_vw4 = JoinViews("Network + Flow + Avail Counts", join_vw+"."+link_lyr+".ID", count_vw+".ID", )

	dim baseyr_oth_adjusted_vmt[years.length+1] // initialize
	dim other_count[years.length+1]

	baseyr_oth_adjusted_vmt[1] = baseyr_adjusted_vmt // method 1 and method 2 identical
	other_count[1] = null // nothing for base year 2015

	for _yr = 1 to years.length do
	    //Add fields
	    SetView(join_vw4)
	    other_count[_yr+1] = SelectByQuery("OthCounts", "Several", "Select * where " + awdt_fields[_yr] + " > 0",)
		CreateExpression(join_vw4, awdt_fields[_yr] + "_VMT", awdt_fields[_yr] + '* length', {{"Type", "Real"}})

	    //Aggregate for links with other counts
	    //County
	    Agg = {{vmt_fld, "sum"}, {awdt_fields[_yr] + "_VMT", "sum"}}
        agg_county_vw = AggregateTable("VMTAgg", join_vw4+"|OthCounts", "MEM", "VMTAgg.bin", "COUNTY", Agg, ) //aggregate by county
	    County_oth_count_Vs = GetDataVectors(agg_county_vw+"|", {"COUNTY", vmt_fld, awdt_fields[_yr] + "_VMT"}, {{"Return Options Array", "True"}, {"Sort Order", {{"COUNTY", "Ascending"}}}})

	    //Read county-level count and model VMT on links with validation counts into vectors
	    FACCOUNTY_OTH_COUNT_COUNT = null
	    FACCOUNTY_OTH_COUNT_VOL = null

	    for II = 1 to County_oth_count_Vs.COUNTY.length do
            tmp = County_oth_count_Vs.(awdt_fields[_yr] + "_VMT")
            FACCOUNTY_OTH_COUNT_COUNT.(i2s(County_oth_count_Vs.COUNTY[II])).(awdt_fields[_yr] + "_VMT") = tmp[II]
	    	tmp_vol = County_oth_count_Vs.(vmt_fld)
	    	FACCOUNTY_OTH_COUNT_VOL.(i2s(County_oth_count_Vs.COUNTY[II])).(vmt_fld) = tmp_vol[II]
        end

	     //Calculate scale factor
	     dim baseyr_oth_vmt_county[County_Vs.COUNTY.length]
	     for II = 1 to County_Vs.COUNTY.length do
	         if nz(FACCOUNTY_OTH_COUNT_COUNT.(i2s(County_Vs.COUNTY[II])).(awdt_fields[_yr] + "_VMT")) = 0 then do
	     	    scale_fac = 1 // if no county counts exist
	     	end
	     	else do
	     	    baseyr_oth_vmt_count_county = FACCOUNTY_OTH_COUNT_VOL.(i2s(County_Vs.COUNTY[II])).(vmt_fld)
	             count_oth_vmt_count_county = FACCOUNTY_OTH_COUNT_COUNT.(i2s(County_Vs.COUNTY[II])).(awdt_fields[_yr] + "_VMT")
	     	    scale_fac = count_oth_vmt_count_county / baseyr_oth_vmt_count_county // scale factor is the ratio of count VMT to model VMT on links with validation counts
	     	end

	     	baseyr_oth_vmt_county[II] = nz(FACCOUNTY_VOL.(i2s(County_Vs.COUNTY[II])).(vmt_fld)) * scale_fac // adjusted VMT is the base VMT multiplied by the scale factor
	     end

         baseyr_oth_adjusted_county_total = VectorStatistic(A2V(baseyr_oth_vmt_county), "Sum", )	// total adjusted VMT is the total of the county-specific adjusted VMT


	    //Facility type
	    agg_ft_vw = AggregateTable("VMTAgg", join_vw4+"|OthCounts", "MEM", "VMTAgg.bin", "FTYPE", Agg, ) //aggregate by functional class
	    SetView(agg_ft_vw)
	    FT_oth_count_Vs = GetDataVectors(agg_ft_vw+"|", {"FTYPE", vmt_fld, awdt_fields[_yr] + "_VMT"}, {{"Return Options Array", "True"}, {"Sort Order", {{"FTYPE", "Ascending"}}}})

	    //Read ftype-level count and model VMT on links with validation counts into vectors
	    FACFT_OTH_COUNT_COUNT = null
	    FACFT_OTH_COUNT_VOL = null

	    for II = 1 to FT_oth_count_Vs.FTYPE.length do
            tmp = FT_oth_count_Vs.(awdt_fields[_yr] + "_VMT")
            FACFT_OTH_COUNT_COUNT.(i2s(FT_oth_count_Vs.FTYPE[II])).(awdt_fields[_yr] + "_VMT") = tmp[II]
	    	tmp_vol = FT_oth_count_Vs.(vmt_fld)
	    	FACFT_OTH_COUNT_VOL.(i2s(FT_oth_count_Vs.FTYPE[II])).(vmt_fld) = tmp_vol[II]
        end

	    //Calculate scale factor
	    dim baseyr_oth_vmt_ft[FT_Vs.FTYPE.length]
	    for II = 1 to FT_Vs.FTYPE.length do
	        if nz(FACFT_OTH_COUNT_COUNT.(i2s(FT_Vs.FTYPE[II])).(awdt_fields[_yr] + "_VMT")) = 0 then do
	    	    scale_fac = 1 // if no ftype counts exist
	    	end
	    	else do
	    	    baseyr_oth_vmt_count_ft = FACFT_OTH_COUNT_VOL.(i2s(FT_Vs.FTYPE[II])).(vmt_fld)
	            count_oth_vmt_count_ft = FACFT_OTH_COUNT_COUNT.(i2s(FT_Vs.FTYPE[II])).(awdt_fields[_yr] + "_VMT")
	    	    scale_fac = count_oth_vmt_count_ft / baseyr_oth_vmt_count_ft // scale factor is the ratio of count VMT to model VMT on links with validation counts
	    	end

	    	baseyr_oth_vmt_ft[II] = nz(FACFT_VOL.(i2s(FT_Vs.FTYPE[II])).(vmt_fld)) * scale_fac // adjusted VMT is the base VMT multiplied by the scale factor
	    end

        baseyr_oth_adjusted_ft_total = VectorStatistic(A2V(baseyr_oth_vmt_ft), "Sum", ) // total adjusted VMT is the total of the ftype-specific adjusted VMT

		baseyr_oth_adjusted_vmt[_yr+1] = (baseyr_oth_adjusted_county_total + baseyr_oth_adjusted_ft_total) / 2 // adjusted VMT is the average of the county and ftype adjusted VMT - first year is base year
	end

	SetVs = {{vmt_vw+".Adjusted VMT - Method 1", A2V(baseyr_oth_adjusted_vmt)},
			 {vmt_vw+".NumLinksWithOtherCounts - Method 1", A2V(other_count)}}

	SetDataVectors(vmt_vw+"|", SetVs, ) // Update output table with second method results

//EndStep
NextStep= "Cleanup"

	RunMacro("G30 File Close All")
	Return(1)

//EndStep
EndMacro

/*-----------------------------**
** Syntax for "TCB ..." Macros **
**-----------------------------*/
/*
Macros used in batch run
========================

"TCB Error" (error_message)                                             report batch run error
    error_message:  message to put into the batch error file

"TCB Run Procedure" (step_idx, proc_name, Options, ReturnArray)         run a procedure
    step_idx:       integer, sub-step index for the procedure inside current batch step
    proc_name:      string, name of procedure to run
    Options:        array, options passed to the procedure
    ReturnArray:    array, values returned from the procedure
    Return:         integer, 1 if successful; 0 otherwise

"TCB Run Operation" (step_idx, oper_name, Options)                      run an operation
    step_idx:       integer, sub-step index for the operation inside current batch step
    oper_name:      string, name of operation to run
    Options:        array, options passed to the operation
    Return:         integer, 1 if successful; 0 otherwise

"TCB Add DB Layers" (db_file)                                           add database layers to workspace
    db_file:        database file (*.dbd, *.cdf)
    Return:         array of strings, actual names of layers opened

"TCB Add RS Layers" (rs_file, return_flag, new_map_flag)                add a route system to current or new map
    rs_file:        string, route system file (*.rts)
    return_flag:    string, "All" or null
    new_map_flag:   integer, 1 - to open a new map with the route system,
                             0 - add route system to current map
    Return:         array of strings, all layers in the route system if return_flag = "All", or
                    string, name of route system layer if return_flag <> "All"

"TCB OpenTable" (desired_view_name, table_type, table_spec)             open a table file
    ( for arguments and return values, see GISDK help on OpenTable() )

"TCB OpenMatrix" (file_name, file_based)                                open a matrix file
    ( for arguments and return values, see GISDK help on OpenMatrix() )

"TCB Add View Fields" ({view_name, Field_Info, Default_Values})         add/modify fields to/in a dataview
    view_name   string, name of dataview
    Field_Info  array, field specifications in the format of
                {name, type[, width[, decimals[, indexing [, action[, position]]]]]},
                name      string, name of a field, or
                          array of strings, in the form of {start-field, end-field} for a range of fiends.
                type      string, value: integer|real|character
                indexing  strings,  value: true|yes|false|no
                width     integer, field width
                decimals  integer, number of decimals
                position  integer, desired position of field in question
                action    string, value: REFORMAT -- change format of existing field(s)
                                         REPLACE  -- replace an existing field at a position with new field(s)
                                         INSERT   -- insert new field(s) in a desired position
                                         APPEND   -- append new field(s) at the end of existing fields
    Default_Value   a single value to initialize all specified fields, or
                    an array of values to initialize each field
    Return:         integer, 1 if successful; 0 otherwise
*/

/*----------------------------------------------------------------------------------------------**
** The following macros -- SEMCOGImportTabFile, SEMCOGExportMatrices, SEMCOG Run Loops, and **
** SEMCOGGetFileLocation -- are used in the interface between UrbanSIM and Travel Demand Model**
** Updated by J. Chen for E6-- March 20, 2013	(not being tested yet)    **
**----------------------------------------------**/
Macro "SEMCOG Init"
    Shared  model_ui, scen_data_dir, project_name

    BatchTimerOpts.NoBatchTiming = True
    BatchOptions.MatrixCompression = True

    tmp = SplitPath(GetInterface())
    ini_file = tmp[1] + tmp[2] + "SEMCOG_E7.ini"
    {mod_file, model_ui, scenario_file, scen_data_dir} = RunMacro("TCP Get Project Files", ini_file, &errMsg)
    if mod_file = null then do ShowMessage(errMsg) return() end

    project_name = "SEMCOG Model"
    {MacroInfo, Args, Opts, VarInfo} = RunMacro("TCP Read Planning Model", mod_file, scen_data_dir)
    if MacroInfo = null then return()
    {StepMacro, StepTitle, StepFlag} = MacroInfo
    StageName = Args[1]

    return({scenario_file, StepMacro, StepTitle, StepFlag, StageName, Args})
EndMacro




Macro "SEMCOGImportTabFile" (opts)
    PROJECT_VERSION = 70216

    {SEMCOGversion,,} = RunMacro("SEMCOG Model Version")
    if SEMCOGversion < PROJECT_VERSION  then do
        ret.error = "You need a SEMCOG UI of build number "+ i2s(PROJECT_VERSION)
        return(ret)
        end

    inputTab     = opts.InputFile
    TazTableFile = opts.DataTable
    joinField    = opts.JoinField

    errMsg1 = "The input file(path) is missing."
    errMsg2 = "Can not open input file '"+inputTab+"'."
    errMsg3 = "The target view is missing."
    errMsg4 = "The target table fields don't match those in the input."
    errMsg5 = "Error updating TAZ table."

    if joinField = null then do
        ret.error = "No join field specified."
        return(ret)
        end

    if TazTableFile = null | GetFileInfo(TazTableFile) = null then do
        ret.error = "Can not find TAZ table."
        return(ret)
        end

    if Trim(inputTab) = null then do
        ret.error = errMsg1
        return(ret)
        end

    if GetFileInfo(inputTab) = null then do
        ret.error = errMsg2
        return(ret)
        end

    on error do
        ret.error = errMsg5
        return(ret)
        end
    on notfound do
        ret.error = errMsg5
        return(ret)
        end

    tabTable = OpenTable("inputTab","CSV",{inputTab,})
    {tabFields, tabFieldSpecs} = GetFields(tabTable,"Numeric")

    idPos = ArrayPosition(tabFields, {joinField}, )
    if idPos = 0 then do
        ret.error = "Join ID field "+joinField+" does not exist in input table."
        return(ret)
        end

    //remove ID from field list
    updateTabFields = ExcludeArrayElements(tabFields, idPos, 1)

    //field specs used to join to the data table
    inputJoinField = tabFieldSpecs[idPos]


    on error do
        ret.error = "Can not open TAZ table"
        return(ret)
        end
    on notfound do
        ret.error = "Can not open TAZ table"
        return(ret)
        end
    targetView = OpenTable("TazTable","FFB",{TazTableFile,})

    on notfound do
        ret.error = errMsg3
        return(ret)
        end

    {viewFields,} = GetFields(targetView,"Numeric")

    //check whether all fields (except id) in the import file can be matched
    //at the target table
    for i = 1 to updateTabFields.length do
        if ArrayPosition(viewFields,{updateTabFields[i]},) = 0 then do
            ret.error = errMsg4
            return(ret)
            end
        end


    joinView = JoinViews("tempJoin",inputJoinField, "["+targetView+"].ID",)

    SetView(joinView)

    //select only matching records
    n = SelectByQuery("Selection","Several","Select * where ["+targetView+"].ID <> null",)
    if n > 0 then do
        on error do
            RunMacro("TCB Error", "User cancel")
            ok = 0
            goto exit
            end
        //synchronize tabFieldSpecs and updateTabFields
        tabFieldSpecs = ExcludeArrayElements(tabFieldSpecs, idPos, 1)
        dataVectors = GetDataVectors(joinView+"|Selection", tabFieldSpecs,)

        dim targetFieldOpts[updateTabFields.length]
        for i = 1 to updateTabFields.length do
            targetFieldOpts[i] = {"["+targetView+"]."+ updateTabFields[i],dataVectors[i]}
            end

        SetDataVectors(joinView+"|Selection", targetFieldOpts,)
        on error default
        end

    CloseView(joinView)
    CloseView(tabTable)
    CloseView(targetView)

    exit:
    return(null)
EndMacro

Macro "SEMCOGExportMatrices" (opts)
    PROJECT_VERSION = 70216

    MATRIX_PATH  = 1
    ROW_INDEX    = 2
    COL_INDEX    = 3
    CORE_OPTS    = 4

    {SEMCOGversion,,} = RunMacro("SEMCOG Model Version")
    if SEMCOGversion < PROJECT_VERSION  then do
        ret.error = "You need a SEMCOG UI of build number "+i2s(PROJECT_VERSION)
        return(ret)
        end

    outputFile     = opts.ExportTo
    matrixOpts     = opts.Matrix

    errMsg1 = "Specified matrix or core does not exist: "
    errMsg2 = "The matrix/core specification is incorrect."
    errMsg3 = "Can not open matrix file: "
    errMsg4 = "Can not write to the output file."
    errMsg5 = "Specified row or column index does not exist: "

    if matrixOpts = null | TypeOf(matrixOpts) <> "array" then do
        ret.error = errMsg2
        return(ret)
        end

    //process matrixOpts to get matrices and cores
    dim MasterOpts[matrixOpts.length]
    for i = 1 to matrixOpts.length do
        matrixFile = matrixOpts[i][MATRIX_PATH]
        if GetFileInfo(matrixFile) = null then do
            ret.error = errMsg1 + matrixFile
            return(ret)
            end

        on error do
            ret.error = errMsg3 +  matrixFile
            return(ret)
            end
        on notfound do
            ret.error = errMsg3 +  matrixFile
            return(ret)
            end

        matrixHandler = OpenMatrix(matrixFile,)

        matrixCores = GetMatrixCoreNames(matrixHandler)
        matrixIndices = GetMatrixIndexNames(matrixHandler)

        row_index = matrixOpts[i][ROW_INDEX]
        col_index = matrixOpts[i][COL_INDEX]

        if ArrayPosition(matrixIndices[1],{row_index},) <= 0 |
           ArrayPosition(matrixIndices[2],{col_index},) <= 0 then do
            ret.error = errMsg5 + matrixFile
            return(ret)
            end

        coreOpts = matrixOpts[i][CORE_OPTS]
        if coreOpts = null then do
            ret.error = errMsg2
            return(ret)
            end

        dim coreNames[coreOpts.length]
        dim coreLabels[coreOpts.length]
        dim coreOrders[coreOpts.length]
        for j = 1 to coreOpts.length do
            coreNames[j] = coreOpts[j][1]
            coreLabels[j] = coreOpts[j][2]

            pos = ArrayPosition(matrixCores,{coreNames[j]},)
            if pos <= 0 then do
                ret.error = "Matrix "+matrixFile+" does not contain core '"+core+"'."
                return(ret)
                end

            coreOrders[j] = pos
            end //for j = 1 to coreOpts.length

        MasterOpts[i] = {}
        MasterOpts[i].matrix = matrixHandler
        MasterOpts[i].indices = {row_index,col_index}
        MasterOpts[i].coreNames = coreNames
        MasterOpts[i].coreLabels = coreLabels
        MasterOpts[i].coreOrders = coreOrders

        end  //for i = 1 to matrixOpts.length

    on error default
    on notfound default


    //make a copy of the first matrix with specified cores only, rename them to output lebals,
    //add cores from other matrices if necessary, export the matrix to file
    //(matrices have to be compatibal)
    theMatrix = MasterOpts[1].matrix

    _indices = MasterOpts[1].indices
    _cores   = MasterOpts[1].coreNames
    _coreLabels = MasterOpts[1].coreLabels
    _coreOrders = MasterOpts[1].coreOrders

    theMc = CreateMatrixCurrency(theMatrix, _cores[1], _indices[1], _indices[2],)

    minfo = GetMatrixInfo(theMatrix)
    matopts  = CopyArray(minfo[6])
    matopts.[File Name] = GetTempFileName("*.mtx")
    matopts.Cores =  _coreOrders
    matopts.Indices = "Current"

    theMatrix = CopyMatrix(theMc, matopts)

    //set core name to be the output labels
    for i = 1 to _coreLabels.length do
        SetMatrixCoreName(theMatrix, _cores[i], _coreLabels[i])
        end

    // add other cores
    on error do
        ret.error = "Input matrices are not compatible."
        return(ret)
        end
    on notfound do
        ret.error = "Input matrices are not compatible."
        return(ret)
        end

    for i = 2 to MasterOpts.length do
        matrix = MasterOpts[i].matrix

        _cores      = MasterOpts[i].coreNames
        _coreLabels = MasterOpts[i].coreLabels
        _indices    = MasterOpts[i].indices

        for j = 1 to _cores.length do
            //add an empty core
            AddMatrixCore(theMatrix, _coreLabels[j])
            theMc = CreateMatrixCurrency(theMatrix, _coreLabels[j],_indices[1],_indices[2],)

            //set cell values from the matrix
            opts.[Force Missing] = "No"
            EvaluateMatrixExpression(theMc,"["+GetMatrixName(matrix)+"].["+_cores[j]+"]",rows,cols,opts)
            end
        end

    on error default
    on notfound default

    on error do
        ret.error = errMsg4
        return(ret)
        end
    fp = OpenFile(outputFile,"w")
    WriteLine(fp," ")
    CloseFile(fp)

    opts = {}
    opts.Complete = "Yes"
    opts.Decimals = 2
    CreateTableFromMatrix(theMatrix,outputFile,"CSV", opts)

    on error default

    //clean up
    theMc = null
    theMatrix = null

    for i = 1 to MasterOpts.length do
        matrix = MasterOpts[i].matrix
        matrix = null
        end


    return(null)
EndMacro

Macro "SEMCOGGetFileLocation"
    ArgOpts = null

    if ArgOpts <> null then do
        ArgOpts.error = null
        return(ArgOpts)
        end

    Ret = RunMacro("SEMCOG Init")
    if Ret = null then do
        ret.error = "Error initiating SEMCOG. Please run SEMCOG setup in TransCAD."
        return()
        end

    {scenario_file, StepMacro, StepTitle, StepFlag, StageName, Args} = Ret

    if !RunMacro("TCP Load Scenario File", scenario_file, Args, &Arr) then  do // if loading not OK
        ret.error = "Error loading scenario file " + scenario_file
        return()
        end
    {, ScenArr, ScenSel} = Arr                                  // since same loading done earlier in project dbox init
    if ScenSel = null then do
        ret.error = "Error loading scenario file " + scenario_file
        return()
        end
    scen_idx = ScenSel[1]
    Args = ScenArr[scen_idx][5]
    ArgOpts = RunMacro("TCP Convert to Argument Options", Args)

    return(ArgOpts)
EndMacro

Macro "StartMacro" (args)
ShowMessage("Started "+i2s(args.length))
exit()
EndMacro

/*
// Import test
// Use TransCAD as an automation server, read UrbanSim Tab delimited text file and update TAZ data table
//
'
' Usage: c:>cscript Semcog_import_test.vbs
'

dim Gisdk
Dim GisdkOptions
Dim ReturnArray
dim UIPath
dim ProjectDir
dim ProjectFilesPath


' Create an instance of TransCAD COM object
Set Gisdk = CreateObject("TransCAD.AutomationServer")

UIPath = "c:\\caliper\\tc48\\"
ProjectDir = "c:\\projects\\semcog\\"
ProjectUrbansimDir = ProjectDir & "urbansim\\"


' initialize path to the SEMCOG UI interface file and data files
UIDatabase =  UIPath & "semcog_ui"
InputTabFile = ProjectUrbansimDir & "tm_input1.txt"


' Create a TransCAD array of options to be sent to the macro function
GisdkOptions = Array(Array("InputFile", InputTabFile), Array("DataTable", ProjectDir & "D05_TazData.bin"), Array("JoinField","ID"))

' Call the macro function to import the UrbanSim Table File into the TAZ bin table
ReturnArray = Gisdk.Macro("SEMCOGImportTabFile", UIDatabase , GisdkOptions)
if Not IsNull(ReturnArray)  then
     d1 = UBound(ReturnArray)
     d2 = UBound(ReturnArray(d1))
     Error = ReturnArray(d1)(d2)
end if



// Export test
// Use TransCAD as an automation server, export cores in Am Highway Skim and AM Transit SKim into comma-delimited text file.
//
'
' Usage: c:>cscript Semcog_export_test.vbs
'

dim Gisdk
Dim GisdkOptions
Dim ReturnArray
dim UIPath
dim ProjectFilesPath
dim ProjectDir
dim ProjectUrbansimDir
dim WSHShell

Set WSHShell = WScript.CreateObject("WScript.Shell")

if IsNull(WSHShell) then
    WSCRIPT.quit(0)
end if

UIPath = "c:\\caliper\\tc48\\"
ProjectDir = "c:\\projects\\semcog\\"
ProjectUrbansimDir = ProjectDir & "urbansim\\"

'

' Create an instance of TransCAD COM object
Set Gisdk = CreateObject("TransCAD.AutomationServer")

' initialize path to the SEMCOG UI interface file and data files
UIDatabase = UIPath & "semcog_ui"

' Name of the output file
OutputTabFile = ProjectUrbansimDir & "output.txt"

' Create matrix options
MatrixOptions = Array( _
                    Array(ProjectDir & "out\\AM_TransitSkim.mtx", "ZoneID","ZoneID", Array ( _
                        Array("Generalized Cost", "General Cost"), _
                        Array("Fare", "AM Fare"), _
                        Array("Transfer Wait Time", "Xfer Wait Time") _
                        ) _
                    ), _
                    Array(ProjectDir & "out\\PM_A_PR_TransitSkim.mtx", "ZoneID", "ZoneID", Array ( _
                        Array("Fare","PM Fare"), _
                        Array("Total IVTT", "Total Time") _
                        ) _
                    ) _
                )

' Create a TransCAD array of options to be sent to the macro function
GisdkOptions = Array(Array("ExportTo", OutputTabFile), Array("Matrix", MatrixOptions))

'Call the macro function to export HYW and Transit matrices to an Urbansim Table File
ReturnArray = Gisdk.Macro("SEMCOGExportMatrices", UIDatabase, GisdkOptions)

if Not IsNull(ReturnArray)  then
     d1 = UBound(ReturnArray)
     d2 = UBound(ReturnArray(d1))
     Error = ReturnArray(d1)(d2)
end if

*/

Macro "test import"
    SEMCOG_BASE = "c:\\projects\\semcog\\"

    opts = {}

    opts.InputFile = SEMCOG_BASE + "urbansim\\tm_input1.txt"
    opts.DataTable = SEMCOG_BASE + "h05_tazdata.bin"
    opts.JoinField = "ID"

    runmacro("SEMCOGImportTabFile", opts)
EndMacro

Macro "test export"
    SEMCOG_BASE = "c:\\semcog_e6b\\"

    matrix = {
        {SEMCOG_BASE + "out\\AM_TransitSkim.mtx", "ZoneID","ZoneID",
                   {
                    {"Generalized Cost","General Cost"},
                    {"Fare", "AM Fare"},
                    {"Transfer Wait Time", "Xfer Wait Time"}
                   }
        },
        {SEMCOG_BASE + "out\\PM_A_PR_TransitSkim.mtx", "ZoneID", "ZoneID",
                   {
                    {"Fare","PM Fare"},
                    {"Access Walk Time", "Access Time"},
                    {"Auto Access IVTT", "Auto IVTT"}
                   }
        }
    }


    opts = {}
    opts.ExportTo = SEMCOG_BASE + "urbansim\\xxx.txt"
    opts.Matrix   = matrix

    SetAlternateInterface("d:\\semcog_e5\\semcog_e5_ui")
    runmacro("SEMCOGExportMatrices", opts)

EndMacro
