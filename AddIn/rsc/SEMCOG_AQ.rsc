//Questions:
// AQ: - Include NFC1-9?  9 is uncertified.  Include centroid connectors (currently no)??
//     - There are a few ramps (NFC_FLAG=RSF) on unrestricted facilities(NFC=3 or 4).
//         - Should these be included as ramps??
//         - Since ramp fraction is ramps/Ramps+Restricted, is this calculation ok?
//     - Should collector-distributors (NFC_FLAG=FCD) be included as ramps?



//SEMCOG Air Quality Reports

//Define all defaults, including filenames and parameters
//  that are not originally part of the Args array. New parameters are
//  added to the existing Args array.
Macro "AQ Defaults" (Args)

    in_dir = Args.Info.[Input Directory]
    out_dir = Args.Info.[Output Directory]

    R = null
    
    //AQ Inputs
    R.[HPMS VMT] = in_dir + "AQ\\HPMS.bin"
    R.[HPMS Factors] = in_dir + "AQ\\HPMS_Factors.bin"
    
    //AQ Outputs
    R.[HPMS Factor Results] = out_dir + "AQ\\HPMS_Factors.bin"
    
    R.[Model VMT] = out_dir + "AQ\\VMT_Model.bin"
    R.[Adjusted VMT] = out_dir + "AQ\\VMT_Adjusted.bin"
    R.[Model VHT] = out_dir + "AQ\\VHT_Model.bin"
    R.[Speed Bins] = out_dir + "AQ\\SpeedBin_%PER_HWY%_%SUBAREA%.bin"
    
    R.[HPMS Report] = out_dir + "AQ\\HPMS Factor Summary.html"
    R.[AQ Report] = out_dir + "AQ\\AQ Summary.html"
    
    //County Crosswalk - HPMS County ID matched with names
    //  (sort not currently controled by array.  Sorted alphabtically for HPMS report.)
    R.[County Crosswalk HPMS] = {"Wayne": {1,2},  //Group wayne and detroit for HPMS
                                 "Oakland": {3}, 
                                 "Macomb": {4}, 
                                 "Washtenaw": {5},
                                 "Monroe": {6}, 
                                 "St Clair": {7},
                                 "Livingston": {8}}
                                 
    //Sort order as in other reports (SEMCOG requested alternate sort below, consistent with HPMS sort)                             
    //R.[County Crosswalk] = {"Detroit": {1},
    //                        "Wayne": {2},
    //                        "Oakland": {3}, 
    //                        "Macomb": {4}, 
    //                        "Washtenaw": {5},
    //                        "Monroe": {6}, 
    //                        "St Clair": {7},
    //                        "Livingston": {8}}
                           
    //County with separate Detroit/Wayne.
    // (Report sorted as listed)
    R.[County Crosswalk] = {"Livingston": {8},
                            "Macomb": {4}, 
                            "Monroe": {6}, 
                            "Oakland": {3}, 
                            "St Clair": {7},
                            "Washtenaw": {5},
                            "Wayne": {2},
                            "Detroit": {1}}
                
    //Counties to include in tri-county summary
    R.TriCounty = {"Detroit", "Wayne", "Oakland", "Macomb"}
    
    //FT Crosswalk, separate into restricted and un-restricted
    R.[FT Crosswalk] = {"Restricted": {1, 2},
                        "Unrestricted": {3,4,5,6,7,9,99}}
                        
    //AT crosswalk, separate into urban and rural
    R.[AT Crosswalk] = {"Rural": {5},
                        "Urban": {1,2,3,4}}  
                        
    //HPMS factors to apply to each facility type
    //Also defines order in which FT-based tables are written
    R.FactorPairs = {"RuralRestricted":"Restricted", 
                     "RuralUnrestricted":"Unrestricted",
                     "UrbanRestricted":"Restricted",
                     "UrbanUnrestricted":"Unrestricted",
                     "RuralRamp":"Restricted",
                     "UrbanRamp":"Restricted"}
                     
    //Column name revisions for HTML report
    //R.ColumnNames = {RuralRestricted:"2 - RuralRestricted", 
    //                RuralUnrestricted:"3 - RuralUnrestricted",
    //                UrbanRestricted:"4 - UrbanRestricted",
    //                UrbanUnrestricted:"5 - UrbanUnrestricted",
    //                RuralRamp:"6 - RuralRamp",
    //                UrbanRamp:"7 - UrbanRamp"}

    R.ColumnNames = {RuralRestricted:"2", 
                    RuralUnrestricted:"3",
                    UrbanRestricted:"4",
                    UrbanUnrestricted:"5",
                    RuralRamp:"6",
                    UrbanRamp:"7"}    
    //footnote applied to all tables
    R.Footnote = '2=RuralRestricted, 3=RuralUnrestricted, 4=UrbanRestricted, 5=UrbanUnrestricted'
    
    
    
    
    
    
    
                     
    //Speed bins (upper limits 2.5... 5 mph increments ... 72.5, 9999)
    //Lower limit inclusive
    R.SpeedBins = {2.5}
    for ii = 1 to 14 do
        R.SpeedBins = R.SpeedBins + {R.SpeedBins[R.SpeedBins.length]+5}
    end
    R.SpeedBins = R.SpeedBins + {9999}
    Args = Args + R

EndMacro

// *****************************************************************************
// SEMCOG AQ Report
Dbox "SEMCOG AQ" (Args)
// Steps:
// 1. Create HMPS Factor file using HPMS table and BY model run
//    - This step should only be run for the base year.
//    - Creates a file named HPMS_Factors in the Output\AQ folder
//    - Requires input BIN file with base year HPMS by County and combinations 
//      of:
//      * Restricted / un-restricted
//      * urban / rural
//    - File should be under Input\AQ\HPMS.bin 
// 
// 2. Create output 
//    - Can be run for the base or forecast year
//    - Requires Input\AQ\HPMS_Factors.bin
// *****************************************************************************

    button "HPMS Factors" 1, 1, 20, 1.4 help: "Compute base year HPMS Factors" do
        RunMacro("HPMS Factors", Args)
    enditem
    
    button "AQ Report" 1, 3, 20, 1.4 help: "Create Air Quality Report" do
        RunMacro("AQ Report", Args)
    enditem
    
    Button "Done" 15, 6, 10, 1.4 cancel do
        Return()
    enditem
    
    close do
        Return()
    enditem

    
EndDbox


Macro "HPMS Factors" (Args)

    shared UT, Scen
    
    //Load AQ defaults, append to the Args array
    RunMacro("AQ Defaults", &Args)
    
    hpms_file = Args.[HPMS VMT]
    hpmsfac_file = Args.[HPMS Factor Results]
    dbd_file = Args.[Highway DB]
    flow_file = Args.[DY Highway Flows]
    
    sum_file = Args.[HPMS Report]
    
    //Open the HPMS Table and daily flow files
    hpms_vw = UT.OpenView(hpms_file)
    flow_vw = UT.OpenView(flow_file)
    
    //Bring the net+Flow into a memory view
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", dbd_file)
    if node_lyr = null or link_lyr = null then Throw(JoinStrings({'Cannot open file:', dbd_file}, ' '))
    
    join_vw = JoinViews("net+flow", link_lyr+".ID", flow_vw+".ID1", )
    //Compute VMT to avoid V_Dist_T / VMT problems
    CreateExpression(join_vw, "CalcVMT", "TOT_Flow * Length", )
    AddFlds = {{"AQ_FT", "String", 20, }, 
               {"AQ_CountyName", "String", 16, },
               {"AQ_Class", "String", 32, }}
    mem_vw = ExportView(join_vw+"|", "MEM", "flow_net", null, {"Additional Fields":AddFlds})
    
    CloseView(join_vw)
    CloseView(flow_vw)
	DropLayerFromWorkspace(link_lyr)
	DropLayerFromWorkspace(node_lyr)
    
    //Compute AQ County and FT
    Vs = GetDataVectors(mem_vw+"|", {"COUNTY", "NFC", "AREA_TYPE"}, {"Return Options Array":True})
    
    SetVs = null
    SetVs.AQ_CountyName = RunMacro("ApplyCrosswalk", Args.[County Crosswalk HPMS], Vs.COUNTY)
    SetVs.AQ_FT = RunMacro("ApplyCrosswalk", Args.[FT Crosswalk], Vs.NFC)
    SetVs.AQ_Class = SetVs.AQ_CountyName + SetVs.AQ_FT
    SetDataVectors(mem_vw+"|", SetVs, )
    
    //Aggregate flows by AQ County and FT
    SetView(mem_vw)
    SelectByQuery("Sel", "Several", "Select * Where AQ_FT != null and AQ_CountyName != null")
    AggFlds = {{"AQ_FT", "DOM", },
               {"AQ_CountyName", "DOM"}, 
               {"CalcVMT", "Sum"}}
    agg_vw = AggregateTable("agg_vw", mem_vw+"|Sel", "MEM", "agg", "AQ_Class", AggFlds, )

    //Create the HPMS factor view
    t = SplitPath(hpmsfac_file)
    t = t[1]+t[2]
    t = Left(t, Len(t)-1)
    if GetFileInfo(t) = null then CreateDirectory(t)
    
    Flds = {{"CountyName", "String", 16, }}
            
    for ftcw in Args.[FT Crosswalk] do 
        Flds = Flds + {{ftcw[1], "Real", 10, 2}}
    end
    hpmsfac_vw = CreateTable("HPMS_Factors", hpmsfac_file, "FFB", Flds)
    
    Vs = GetDataVectors(hpms_vw+"|", {"CountyName"}, {"Return Options Array":True})
    AddRecords(hpmsfac_vw, , , {"Empty Records":Vs.CountyName.length})
    SetDataVectors(hpmsfac_vw+"|", Vs, )
    
    //Create a VMT view to hold model VMT (for reporting)
    t = SplitPath(hpmsfac_file)
    vmt_vw = ExportView(hpmsfac_vw+"|", "MEM", "ModelVMT", , )
            
    //Comapre to HMPS and create factors
    VMT = GetDataVectors(agg_vw+"|", {"AQ_FT", "AQ_CountyName", "CalcVMT"}, {"Return Options Array":True})
    
    for ii = 1 to VMT.AQ_FT.length do
        ft = VMT.AQ_FT[ii]
        cn = VMT.AQ_CountyName[ii]
        
        //Model VMT
        vmt = VMT.CalcVMT[ii]
        
        //Match HPMS tables with aggregated model data
        hpms_rec = LocateRecord(hpms_vw+"|", "CountyName", {cn}, {"Exact":"True"})
        hpmsfac_rec = LocateRecord(hpmsfac_vw+"|", "CountyName", {cn}, {"Exact":"True"})
        vmt_rec = LocateRecord(vmt_vw+"|", "CountyName", {cn}, {"Exact":"True"})
        if hpms_rec = null or hpmsfac_rec = null or vmt_rec = null then do
            Throw("Error reading HPMS records or writing factors to view")
        end
        
        //Compute and write factor to view
        vmt_vw.(ft) = vmt
        hpms_vmt = hpms_vw.(ft)
        fac = hpms_vmt / vmt
        
        hpmsfac_vw.(ft) = fac
    
    end
    
    //Add a duplicate record to the factor view only, to be applied for Detroit
    // (Detroit and Wayne are combined in HPMS estimates)
    hpmsfac_rec = LocateRecord(hpmsfac_vw+"|", "CountyName", {"Wayne"}, {"Exact":"True"})
    {flds, } = GetFields(hpmsfac_vw, "All")
    rec_vals = GetRecordValues(hpmsfac_vw, hpmsfac_rec, flds)
    rec_vals[1][2] = "Detroit"
    AddRecord(hpmsfac_vw, rec_vals)
    
    // ************* Write to a report ****************
    
    //Local Perf object for report writing
    SetAlternateInterface(Scen.Vars.sumui_file)
    Perf = CreateObject("Performance")
    SetAlternateInterface()

    //Initialize the report    
    Perf.SetArgs(Args)
    Perf.File = sum_file
    Perf.fp = Perf.HTML_Headers()
    fp = Perf.fp
    
    
    //Basic scenario info
    WriteLine(fp,'<h1>SEMCOG Air Quality Report - HPMS Adjustment Factors</h1>')
    WriteLine(fp,'<div class="indent_h1">')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Scenario Name: </span>' + Perf.Args.Info.Name + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Input Directory: </span>' + Perf.Args.Info.[Input Directory] + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Output Directory: </span>' + Perf.Args.Info.[Output Directory] + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Report File: </span>' + Perf.File + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Report Created on: </span>' + UT.FormatDate() + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Scenario Description: </span> '+ Perf.Args.Info.Description +'</div>')
    WriteLine(fp, '</div>')
    
    //Write the tables
    Tables = null
    //Model VMT
    TB = null
    TB.Section1 = null
    TB.Name = "Model VMT by County and Facility Type"
    TB.Table = Perf.ViewToTable(vmt_vw, {"Marginals":"True"})
    Tables = Tables + {CopyArray(TB)}
    
    //HPMS VMT
    TB = null
    TB.Section1 = null
    TB.Name = "HPMS VMT by County and Facility Type"
    TB.Table = Perf.ViewToTable(hpms_vw, {"Marginals":"True"})
    Tables = Tables + {CopyArray(TB)}
    
    //HPMS Factors
    TB = null
    TB.Section1 = null
    TB.Name = "Adjustment Factors by County and Facility Type"
    TB.Table = Perf.ViewToTable(hpmsfac_vw, {"Marginals":"False"})
    TB.Table.Formats = "*.0000"
    TB.Table.Class = "dataframe no-last-any"
    Tables = Tables + {CopyArray(TB)}
    
    //Indent the tables
    WriteLine(fp, '<div style="margin-left: 30px;">')
    
    Perf.WriteTables(Tables, {"NoHeader":True})
    
    WriteLine(fp, "</div>")
    
    
    //Close the report
    Perf.HTML_Close()
    Perf = null
    
    CloseView(mem_vw)
    CloseView(vmt_vw)
    CloseView(hpmsfac_vw)
    CloseView(hpms_vw)
    CloseView(agg_vw)

EndMacro


Macro "AQ Report" (Args)

    shared UT, Scen

    //Load AQ Defaults, append to the Args array
    RunMacro("AQ Defaults", &Args)
    
    //Inputs
    fac_file = Args.[HPMS Factors]
    dbd_file = Args.[Highway DB]
    flow_file = Args.[DY Highway Flows]
    perflow_files = UT.Expand(Args.[Highway Flows])
    
    //Outputs
    mdlvmt_file = Args.[Model VMT]
    adjvmt_file = Args.[Adjusted VMT]
    mdlvht_file = Args.[Model VHT]
    speedbin_files = UT.Expand(Args.[Speed Bins])
    
    sum_file = Args.[AQ Report]
    
    FactorPairs = Args.FactorPairs
    SpeedBins = Args.[SpeedBins]
    pers = Args.HwyPeriods
    TriCounty = Args.TriCounty
    CountyCrosswalk = Args.[County Crosswalk]
    ColumnNames = Args.ColumnNames
    Footnote = Args.Footnote
    
    //Make sure all output file paths exist
    check_files = {mdlvmt_file, adjvmt_file, mdlvht_file, sum_file} + speedbin_files
    for fn in check_files do
        t = SplitPath(fn)
        t = t[1]+t[2]
        t = Left(t, Len(t)-1)
        if GetFileInfo(t) = null then CreateDirectory(t)
    end
       
    //Open the HPMS Table and daily flow files
    fac_vw = UT.OpenView(fac_file)
    flow_vw = UT.OpenView(flow_file)
    
    // *** Bring the net+Flow into a memory view ***
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", dbd_file)
    if node_lyr = null or link_lyr = null then Throw(JoinStrings({'Cannot open file:', dbd_file}, ' '))
    
    join_vw = JoinViews("net+flow", link_lyr+".ID", flow_vw+".ID1", )
    //Compute VMT to avoid V_Dist_T / VMT problems
    CreateExpression(join_vw, "CalcVMT", "TOT_Flow * Length", )
    AddFlds = {{"CountyName", "String", 16, },
               {"AQ_FT", "String", 20, }, 
               {"AQ_FT2", "String", 20, }, //with ramps
               {"AQ_AT", "String", 20, },
               {"AQ_Class", "String", 32, }}     //AT+FT2(w/ramp)
    mem_vw = ExportView(join_vw+"|", "MEM", "flow_net", null, {"Additional Fields":AddFlds})
    
    CloseView(join_vw)
    CloseView(flow_vw)
    
    
    // *** Compute county, FT, AT, and class values ***
    Vs = GetDataVectors(mem_vw+"|", {"COUNTY", "NFC", "AREA_TYPE", "NFC_FLAG"}, {"Return Options Array":True})
    
    SetVs = null
    SetVs.CountyName = RunMacro("ApplyCrosswalk", Args.[County Crosswalk], Vs.COUNTY)
    SetVs.AQ_FT = RunMacro("ApplyCrosswalk", Args.[FT Crosswalk], Vs.NFC)
    SetVs.AQ_FT2 = if Left(Vs.NFC_FLAG, 1) = "R" then "Ramp" else SetVs.AQ_FT
    SetVs.AQ_AT = RunMacro("ApplyCrosswalk", Args.[AT Crosswalk], Vs.AREA_TYPE)
    SetVs.AQ_Class = SetVs.AQ_AT + SetVs.AQ_FT2
    
    SetDataVectors(mem_vw+"|", SetVs, )
    
    // *** Run cross-tabulation on VMT and VHT ***
    SetView(mem_vw)
    SelectByQuery("Sel", "Several", "Select * Where AQ_FT2 != null and AQ_AT != null and CountyName != null", )

    Opts = null
    Opts.RowFields = {"CountyName"}
    Opts.ColumnField = "AQ_Class"
    Opts.SumField = "CalcVMT"
    
    //Set sort order
    {CountyList, } = TransposeArray(Args.[County Crosswalk])
    {ClassList, } = TransposeArray(FactorPairs)
    Opts.RowHeaders = {CountyList}
    Opts.ColHeaders = ClassList
    
    mdlvmt_vw = RunMacro("Crosstab", "VMT Model", "FFB", mdlvmt_file, mem_vw+"|Sel", Opts)
    
    Opts.SumField = "Tot_VHT"
    mdlvht_vw = RunMacro("Crosstab", "VHT Model", "FFB", mdlvht_file, mem_vw+"|Sel", Opts)
    
    
    // *** Apply HPMS Factors (in copy of VMT table) ***
    ExportView(mdlvmt_vw+"|", "FFB", adjvmt_file, , )
    adjvmt_vw = OpenTable("VMT Adjusted", "FFB", {adjvmt_file}, )
    
    join_vw = JoinViews("VMT+HMPS", adjvmt_vw+".CountyName", fac_vw+".CountyName", )
    {flds, } = GetFields(join_vw, "All")
    
    Vs = GetDataVectors(join_vw+"|", flds, {"Return Options Array":True})
    
    SetVs = null
    for fp in FactorPairs do
        SetVs.(fp[1]) = Vs.(fp[1]) * Vs.(fp[2])
    end
    SetDataVectors(join_vw+"|", SetVs, )

    
    
    // ************* Write to a report - VMT and VHT Summary ****************
    
    //Local Perf object for report writing
    SetAlternateInterface(Scen.Vars.sumui_file)
    Perf = CreateObject("Performance")
    SetAlternateInterface()

    //Initialize the report    
    Perf.SetArgs(Args)
    Perf.File = sum_file
    Perf.fp = Perf.HTML_Headers()
    fp = Perf.fp
    
    
    //Basic scenario info
    WriteLine(fp,'<h1>SEMCOG Air Quality Report</h1>')
    WriteLine(fp,'<div class="indent_h1">')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Scenario Name: </span>' + Perf.Args.Info.Name + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Input Directory: </span>' + Perf.Args.Info.[Input Directory] + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Output Directory: </span>' + Perf.Args.Info.[Output Directory] + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Report File: </span>' + Perf.File + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Report Created on: </span>' + UT.FormatDate() + '</div>')
    WriteLine(fp,'<div class="titleInfo"><span class="blueText">Scenario Description: </span> '+ Perf.Args.Info.Description +'</div>')
    WriteLine(fp, '</div>')
    
    //Write the tables, including ramp fractions and totals for tri-county
    Tables = null
    //Model VMT
    TB = null
    TB.Section1 = null
    TB.Name = "Model VMT by County and Facility Type"
    TB.Table = Perf.ViewToTable(mdlvmt_vw, {"Marginals":"True"})
    TB.Table.Class = "dataframe no-last-row"
    RunMacro("RampFraction", Args, &TB.Table)
    Tables = Tables + {CopyArray(TB)}
    
    //Adjusted VMT
    TB = null
    TB.Section1 = null
    TB.Name = "Adjusted VMT by County and Facility Type"
    TB.Table = Perf.ViewToTable(adjvmt_vw, {"Marginals":"True"})
    TB.Table.Class = "dataframe no-last-row"
    RunMacro("RampFraction", Args, &TB.Table)
    Tables = Tables + {CopyArray(TB)}
    
    //Model VHT
    TB = null
    TB.Section1 = null
    TB.Name = "Model VHT by County and Facility Type"
    TB.Table = Perf.ViewToTable(mdlvht_vw, {"Marginals":"True"})
    TB.Table.Class = "dataframe no-last-row"
    RunMacro("RampFraction", Args, &TB.Table)
    Tables = Tables + {CopyArray(TB)}
    
    //Close the report
    //... Will close the report after writing speed bin data Perf.HTML_Close()
 
    //Close views
    CloseView(mem_vw)
    CloseView(join_vw)
    CloseView(fac_vw)
    CloseView(mdlvmt_vw)
    CloseView(mdlvht_vw)
    CloseView(adjvmt_vw) 
    
    // *** Compute Speed Bins ***
    TriCountyIds = TriCounty.map( do(x) Return(CountyCrosswalk.(x)) end)
    TriCountyIds = TriCountyIds.flatten()
    speedbin_groups = {"Region", "Tri-County"}
    speedbin_qrys = {null,  //all records
                     "Select * Where County = " + JoinStrings(TriCountyIds, " or County = ")}
                     
    for _subarea = 1 to speedbin_groups.length do
        for _per = 1 to pers.length do
            per = pers[_per]
            
            flow_vw = UT.OpenView(perflow_files[_per])
            join_vw = JoinViews("Hwy+Flows"+per, link_lyr+".ID", flow_vw+".ID1", )
            AddFlds = {{"AQ_FT", "String", 20, },
                       {"AQ_AT", "String", 20, },
                       {"AQ_Class", "String", 32, }, 
                       {"AB_SpeedBin", "Integer", 10, },
                       {"BA_SpeedBin", "Integer", 10, }}
                       
            //Select subarea records
            SetView(join_vw)
            qry = speedbin_qrys[_subarea]
            if qry = null then do
                join_vwset = join_vw+"|"
            end else do
                SelectByQuery("S", "Several", qry, )
                join_vwset = join_vw+"|S"
            end
                       
            mem_vw = ExportView(join_vwset, "MEM", join_vw+"_MEM", , {"Additional Fields":AddFlds})
            CloseView(join_vw)
                       
            Vs = GetDataVectors(mem_vw+"|", {"NFC", "AREA_TYPE", "AB_Speed", "BA_Speed"}, {"Return Options Array":True})
                       
            SetVs = null
            SetVs.AQ_FT = RunMacro("ApplyCrosswalk", Args.[FT Crosswalk], Vs.NFC)
            SetVs.AQ_AT = RunMacro("ApplyCrosswalk", Args.[AT Crosswalk], Vs.AREA_TYPE)
            SetVs.AQ_Class = SetVs.AQ_AT + SetVs.AQ_FT
            SetVs.AB_SpeedBin = RunMacro("SpeedBin", SpeedBins, Vs.AB_Speed)
            SetVs.BA_SpeedBin = RunMacro("SpeedBin", SpeedBins, Vs.BA_Speed)
            
            SetDataVectors(mem_vw+"|", SetVs, )
                       
            // *** Run cross-tabulations ***
            Opts = null
            Opts.RowFields = {"AB_SpeedBin"}
            Opts.ColumnField = "AQ_Class"
            Opts.SumField = "Tot_VHT"
            Opts.RowHeaders = {V2A(Vector(SpeedBins.length, "Integer", {{"Sequence", 1, 1}}))}
            {ClassList, } = TransposeArray(FactorPairs)
            ClassList = Subarray(ClassList, 1, 4) //Don't separate ramps (first 4 class groups)
            Opts.ColHeaders = ClassList
            
            ab_ct = RunMacro("Crosstab", "AB_SpeedCT", "MEM", "AB_SpeedCT", mem_vw+"|", Opts)
            Opts.RowFields = {"BA_SpeedBin"}
            ba_ct = RunMacro("Crosstab", "BA_SpeedCT", "MEM", "BA_SpeedCT", mem_vw+"|", Opts)
            
            // *** Combine AB+BA and compute percentages ***
            
            ABV = GetDataVectors(ab_ct+"|", ClassList, )
            BAV = GetDataVectors(ba_ct+"|", ClassList, )
            
            SetVs = null
            for ii = 1 to ABV.length do
                //Add AB+BA
                V = nz(ABV[ii]) + nz(BAV[ii])
                
                //And get %s
                S = VectorStatistic(V, "Sum", )
                V = if S > 0 then (V / S) else 0
                SetVs.(ClassList[ii]) = V
            end
            
            // *** Write the percentages ***
            //Use the AB view, since we no longer need it.
            //Rename the column header row
            SetDataVectors(ab_ct+"|", SetVs, )
            
            //Write table to disk
            speedbin_file = Substitute(speedbin_files[_per], "%SUBAREA%", speedbin_groups[_subarea], )
            ExportView(ab_ct+"|", "FFB", speedbin_file, , )
            
            //Use correct speed bin field name
            tmp_vw = OpenTable("tmp", "FFB", {speedbin_file})
            UT.RenameViewFields({{"AB_SpeedBin", "Speed Bin"}}, tmp_vw)
            CloseView(tmp_vw)
            
            //Create a report table
            TB = null
            TB.Section1 = null
            TB.Name = "VHT Share by Speed Bin for " + per + " Period - " + speedbin_groups[_subarea]
            TB.Table = Perf.ViewToTable(ab_ct, {"Marginals":"True"})
            TB.Table.Formats = "*0.0000%"
            TB.Table.Class = "dataframe no-last-col"
            
            //Remove total column, leaving only row
            tmp = TransposeArray(TB.Table.TableData)
            tmp = ExcludeArrayElements(tmp, tmp.length, 1)
            TB.Table.TableData = TransposeArray(tmp)
            tmp = null
            TB.Table.ColNames = ExcludeArrayElements(TB.Table.ColNames, TB.Table.ColNames.length, 1)
            
            //Adjust column names
            TB.Table.ColNames[1] = "Speed Bin" //Use nice header (eliminates[])
            TB.Table.ColNames = TB.Table.ColNames.map( do (x)  Return(if ColumnNames.(x) != null then ColumnNames.(x) else x) end )
            
            rn = {"<"+Format(SpeedBins[1], "*0.0")+" mph"}
            for ii = 2 to (SpeedBins.length - 1) do
                rn = rn + {"["+Format(SpeedBins[ii-1], "*0.0")+","+Format(SpeedBins[ii], "*0.0")+")"}
            end
            rn = rn + {">="+Format(SpeedBins[SpeedBins.length-1], "*0.0")+" mph", "Total"}
            TB.Table.RowNames = CopyArray(rn)
            TB.Footnote = Footnote
            
            Tables = Tables + {CopyArray(TB)}
            
            //Close all in-looop views
            CloseView(ab_ct)
            CloseView(ba_ct)
            CloseView(mem_vw)
            
        end //_per
    end //_subarea
    
    // *** Write the report to file ***
    
    //Indent the tables
    WriteLine(fp, '<div style="margin-left: 30px;">')
    Perf.WriteTables(Tables, {"NoHeader":True})
    WriteLine(fp, "</div>")
    
    //Close the report
    Perf.HTML_Close()
    Perf = null

    
    //Close line layer
    DropLayerFromWorkspace(link_lyr)
	DropLayerFromWorkspace(node_lyr)

EndMacro

// *****************************************************************************
// Utility Macros

//Convert NFC or AT using crosswalk
Macro "ApplyCrosswalk" (cw, VEC)
    
    //FT Crosswalk
    RES = Vector(VEC.length, "String", )
    for c in cw do
        {c_name, c_list} = c
        for val in c_list do
            RES = if VEC = val then c_name else RES
        end
    end
      
    Return(RES)
    
EndMacro

Macro "SpeedBin" (bins, speeds)

    RV = Vector(speeds.length, "Integer", )
    for ii = 1 to bins.length do
        RV = if (RV = null and speeds < bins[ii]) then ii else RV
    end
    RV = if RV = null then bins.length else RV //over max? put in highest bin.
    RV = if speeds = null  then null else RV   //null speed?  null bin.
    
    Return(RV)

EndMacro
//JoinStrings function that works with vectors 
//  (All elements must be strings, does not conver values to strings)
Macro "JoinStringsV" (arr, del)
    VJ = CopyVector(arr[1])
    for ii = 2 to arr.length do
        VJ = VJ + del + CopyVector(arr[ii])
    end
    
    Return(VJ)
EndMacro

//Add ramp fraction calculations to a table for report writing, 
// along with tri-coutny totals
Macro "RampFraction" (Args, Table) 

    TriCounty = Args.TriCounty

    //Remeber original dimensions
    RN = CopyArray(Table.RowNames)
    CN = ExcludeArrayElements(CopyArray(Table.ColNames), 1, 1) //Eclude row name header
    TD = CopyArray(Table.TableData)

    //Adjut total row name
    Table.RowNames[Table.RowNames.length] = "SEMCOG Total"
    
    //SEMCOG Ramp Fractions
    Table.RowNames = Table.RowNames + {"SEMCOG Ramp Fraction"}
    
    totline = Table.TableData[Table.TableData.length]
    dim newline[totline.length]
    newline[5] = totline[5] / zn((totline[5]+totline[1]), )
    newline[6] = totline[6] / zn((totline[6]+totline[3]), )
    Table.TableData = Table.TableData + {newline}
    
    //Tri-County totals
    dim tot_tri[totline.length]
    for ii = 1 to RN.length do
        for jj = 1 to CN.length do
            if ArrayPosition(TriCounty, {RN[ii]}, ) > 0 then do
                tot_tri[jj] = nz(tot_tri[jj]) + nz(TD[ii][jj])
            end
        end
    end
    Table.TableData = Table.TableData + {tot_tri}
    Table.RowNames = Table.RowNames + {"Tri-County Total"}
    
    //Tri-County Ramp-fractions
    Table.RowNames = Table.RowNames + {"Tri-County Ramp Fraction"}
    
    dim newline[tot_tri.length]
    newline[5] = tot_tri[5] / zn((tot_tri[5]+tot_tri[1]), )
    newline[6] = tot_tri[6] / zn((tot_tri[6]+tot_tri[3]), )
    Table.TableData = Table.TableData + {newline}
    
    //Set up formats
    dim fmt[Table.TableData.length, Table.TableData[1].length]
    for ii = 1 to fmt.length do
        for jj = 1 to fmt[ii].length do
            
            if ii = 10 or ii = 12 then do //VMT fractions
                fmt[ii][jj] = "*.00%"
            end else do //Everything else
                fmt[ii][jj] = "*,."
            end
        end
    end
    Table.Formats = fmt
    
    
    
EndMacro
//run a cross-tabulation, return a dataview with results
Macro "Crosstab" (new_vw, new_typ, new_file, vwset, InOpts) //RowArr, Col, Val, Method)
    //new_vw = name of view to return
    //type of view to return (e.g., FFB, CSV, MEM)
    //filename for view to return
    //vwset = view containing source data
    //Opts.RowFields = Array of field names to use in rows for the tabulation (one or more)
    //Opts.ColumnField = Field name to use in columns for the tabulation
    //Opts.SumField = Field to summarize in the tabulation
    //Opts.RowHeaders = <Optional> Array of sorted lists of values for each row field (must match RowFields length)
    //Opts.ColHeaders = <Optional> Sorted list of values for column headers
    // -- not yet supported: Method = "SUM", "MIN", "MAX", "DOM" (DOMINANT), "AVG" (AVERAGE), "STDDEV" or "COUNT"
    
    // *** Load Opts ***
    RowArr = InOpts.RowFields
    Col = InOpts.ColumnField
    Val = InOpts.SumField
    RowHeadersOverride = InOpts.RowHeaders //optional input
    ColHeadersOverride = InOpts.ColHeaders //optional input
    Method = "Sum" //Only supports SUM at this time
    
    // *** Copy the view to a memory view so we can work w/o modifying ***
    vw = ExportView(vwset, "MEM", "MemForCrosstab", , )
    set = null
    vwset = vw+"|"
    
    // *** Create tabulation fields ***
    str = GetTableStructure(vw)
    {flds, } = GetFields(vw, "All")
    tab_flds = RowArr + {Col}
    dim tab_flds_str[RowArr.length+1]
    for ii = 1 to tab_flds.length do
        idx = ArrayPosition(flds, {tab_flds[ii]}, )
        if idx = 0 then Throw("Cross Tabulation Field not Found")
        
        if str[idx][2] = "String" then do
            tab_flds_str[ii] = tab_flds[ii]
        end else do
            tab_flds_str[ii] = CreateExpression(vw, "__TAB__"+String(ii)+"__", "String("+tab_flds[ii]+")", )
        end
    end
    row_flds = ExcludeArrayElements(tab_flds_str, tab_flds_str.length, 1)
    col_fld = tab_flds_str[tab_flds_str.length]
    
    // *** Create a grouped view ***
    expr = JoinStrings(tab_flds_str, " + '_' + ")
    agg_fld = CreateExpression(vw, "__AggBy__", expr, )
    
    AggSettings = null
    for ii = 1 to tab_flds_str.length do
        AggSettings = AggSettings + {{tab_flds_str[ii], "DOM", }}
    end
    AggSettings = AggSettings + {{Val, Method, }}
    
    agg_vw = AggregateTable("AggForCrostab", vwset, "MEM", "", agg_fld, AggSettings, )
    
    // *** Get unique values for rows ***
    if RowHeadersOverride = null then do //Use all, sorted automatically
        expr = JoinStrings(row_flds, " + '_' + ")
        CreateExpression(agg_vw, "__AggByRow__", expr, )
        RowHeaders = GetDataVectors(agg_vw+"|", {"__AggByRow__"} + row_flds, )
        RowHeaders = SortVectors(RowHeaders, {"Unique":"True"})
    //Or create report using input row headers
    end else do
        RowHeaders = null
        for ii = 1 to RowHeadersOverride.length do
            V = A2V(RowHeadersOverride[ii])
            if V.Type != "string" then V = String(V)
            RowHeaders = RowHeaders + {CopyVector(V)}
        end
        RowHeaders = {RunMacro("JoinStringsV", RowHeaders, "_")} + RowHeaders
    end
    
    // *** Get unique values for columns ***
    if ColHeadersOverride = null then do //Use all, sorted automatically
        V = GetDataVector(vwset, col_fld, )
        ColHeaders = (SortVector(V, {"Unique":"True"}))
    //Or create report using input row headers
    end else do
        ColHeaders = A2V(ColHeadersOverride)
        if ColHeaders.Type != 'string' then ColHeaders = String(ColHeaders)
    end
    ColHeaders = if ColHeaders = null then "<NULL>" else ColHeaders
    
    // *** Create the blank crosstab view ***
    FldNames = null
    FldSpecs = null
    
    //columns for row labels
    for ii = 1 to RowArr.length do
        FldSpecs = FldSpecs + {{RowArr[ii], "String", 32, }}
        FldNames = FldNames + {RowArr[ii]}
    end
    //Column labels
    for ii = 1 to ColHeaders.length do
        FldSpecs = FldSpecs + {{ColHeaders[ii], "Real", 10, 2}}
        FldNames = FldNames + {ColHeaders[ii]}
    end
    
    ct_vw = CreateTable(new_vw, new_file, new_typ, FldSpecs)
    
    //Add empty records with row headings
    AddRecords(ct_vw, , , {"Empty Records":RowHeaders[1].length})
    SetVs = null
    for ii = 1 to RowArr.length do
        SetVs.(RowArr[ii]) = RowHeaders[ii+1]
    end
    SetDataVectors(ct_vw+"|", SetVs, )
    
    // *** Fill each record from the aggregated view ***
    expr = JoinStrings(RowArr, " + '_' + ")
    CreateExpression(ct_vw, "__AggByRow_CT__", expr, )
    
    ct_rec = GetFirstRecord(ct_vw+"|", )
    while ct_rec != null do
    
        for f in ColHeaders do 
            agg_rec = LocateRecord(agg_vw+"|", "__AggBy__", {ct_vw.[__AggByRow_CT__]+"_"+f}, {"Exact":"True"})
            if agg_rec != null then do
                ct_vw.(f) = agg_vw.(Val)
            end 
        end
    
    
        ct_rec = GetNextRecord(ct_vw+"|", ct_rec, )
    end
    
    DestroyExpression(ct_vw+".[__AggByRow_CT__]")
    CloseView(vw)
    CloseView(agg_vw)
    
    Return(ct_vw)

EndMacro
