//SEMCOG Environmental Justice Report

//Define all defaults, including filenames and parameters
//  that are not part of the Args array. New parameters are
//  added to the existing Args array.
Macro "SEMCOG EJ" (Args)

    //Confirm run
    ans = MessageBox("Run the Environmental Justice report for the selected scenario?", 
        {Caption:"Continue?", 
         Buttons:"YesNo", 
         Icon:"Question", Default:"No"})

    if ans != "Yes" then Return()

    input_dir = Args.Info.[Input Directory]
    output_dir = Args.Info.[Output Directory]

    bat_file = Args.[EJ Batch File]
    anaconda_dir = Args.[Anaconda_DIR]
    env_dir = Args.[ENV_DIR]
    env_name = Args.[PYTHON_ENV_NAME]

    status = null
	status=RunProgram(bat_file + " " + input_dir + " " + output_dir + " " + anaconda_dir + " " + env_dir + " " + env_name, {{"Maximize", "True"}})


	if status<>0 then do
		ShowMessage ("EJ Launch Failed!")
		goto quit
	end

    RunMacro("EJ Report", Args)

	ShowMessage("Environmental Justice Report Complete.")
    ok = 1
    return(ok)
    

    quit:
		return(0)

     
    
EndMacro

// RunMacro(SEMCOG EJ)



Macro "EJ Report" (Args)

    shared UT, Scen

    output_dir = Args.Info.[Output Directory]
    EJ_dir = output_dir + "EJ"
    
NextStep= "Define Files and Data"
SetStatus(1, NextStep, )

    //Formats to use
    AccFmt = {"*,.", "*,.0", "*,.0", "*.0", "*.0", "*.0"}
    TimeFmt = "*.00"
    AccFmt1 = {"*.0"}

    //Tables to Write
    TableInfo = {{Title: "Auto Accessibility", File: EJ_dir + "\\EJ_Util_auto.csv", Formats: AccFmt, Style: "dataframe no-last-col", cols:{"Population Group","Jobs","Shopping","NonShopping","College","Hospital","MajorRetail"}},
                 {Title: "Transit Accessibility", file: EJ_dir + "\\EJ_Util_transit.csv", Formats: AccFmt, Style: "dataframe no-last-col", cols:{"Population Group","Jobs","Shopping","NonShopping","College","Hospital","MajorRetail"}},
                 {Title: "Non-Motorized Accessibility", File: EJ_dir + "\\EJ_Util_NM.csv", Formats: AccFmt, Style: "dataframe no-last-col", cols:{"Population Group","Jobs","Shopping","NonShopping","College","Hospital","MajorRetail"}}, 
                   
                 {Title: "Auto Travel Time", File: EJ_dir + "\\EJ_Util_autotime.csv", Formats: TimeFmt, cols:{"Population Group","Work","School/University","Shopping","Maintenance","Discretionary","All"}}, 
                 {Title: "Transit Travel Time", File: EJ_dir + "\\EJ_Util_transittime.csv", Formats: TimeFmt, cols:{"Population Group","Work","School/University","Shopping","Maintenance","Discretionary","All"}},
                 {Title: "Non-Motorized Travel Time", File: EJ_dir + "\\EJ_Util_NMtime.csv", Formats: TimeFmt, cols:{"Population Group","Work","School/University","Shopping","Maintenance","Discretionary","All"}},
                 {Title: "Transit Walkshed", File: EJ_dir + "\\EJ_Util_transitWalkshed.csv", Formats: AccFmt1, cols:{"Population Group","Population share(%)"}}}
    
    //Output Files
    sum_file = Args.[EJ Summary Report]
    

//EndStep
NextStep= "Initialize Report"
SetStatus(1, NextStep, )

    //Local Perf object for report writing
    SetAlternateInterface(Scen.Vars.sumui_file)
    Perf = CreateObject("Performance")
    SetAlternateInterface()

    //Initialize the report    
    Perf.SetArgs(Args)
    Perf.File = sum_file
    Perf.HTML_Headers()
    Perf.fp = Perf.HTML_Headers()
    fp = Perf.fp
    
    //Basic scenario info
    WriteLine(fp,'<h1>SEMCOG ABM Environmental Justice Report</h1>')
    WriteLine(fp,'<div class="indent_h1">')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Scenario Name: </span>' + Perf.Args.Info.Name + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Input Directory: </span>' + Perf.Args.Info.[Input Directory] + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Output Directory: </span>' + Perf.Args.Info.[Output Directory] + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Report File: </span>' + Perf.File + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Report Created on: </span>' + UT.FormatDate() + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Scenario Description: </span> '+ Perf.Args.Info.Description +'</div>')
    WriteLine(fp, '</div>')
    
//EndStep
NextStep= "Write Report"
SetStatus(1, NextStep, )
    
    Tables = null
    
    for TD in TableInfo do
        {table_name, table_file} = TableData
    
        t = SplitPath(TD.File)
        vw = OpenTable(t[3], "CSV", {TD.File})
    
        TB = null
        TB.Section1 = null
        TB.Name = TD.Title
        TB.Table = Perf.ViewToTable(vw, {Marginals:"False"})
        TB.Table.ColNames = TD.cols
        TB.Table.Class = TD.Style
        TB.Table.Formats = TD.Formats

        Tables = Tables + {CopyArray(TB)}
        
    end
    
    //Indent the tables
    WriteLine(fp, '<div style="margin-left: 30px;">')
    Perf.WriteTables(Tables, {"NoHeader":True})
    WriteLine(fp, "</div>")
    
    //Close the report
    Perf.HTML_Close()
    Perf = null


    
//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )

Return(1)

EndMacro