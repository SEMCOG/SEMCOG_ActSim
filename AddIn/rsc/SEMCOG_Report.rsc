// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//
//                              SEMCOG SUMMARY REPORT 
//
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//
//
//Perf = Performance(Args)  Where Args is an optional scenario Args array
//
//Public Methods:
//  .GetSettings --> Displays performance report dialog box
//  .SetAllReports(True/False) --> Turns all reports on or off
//  .CreateReport --> Creates a report using the current settings
//
//  -- Tools to be used by report macros --
//  .ActiveAreas("Network"/"Zones") --> Returns info for active areas by type
//  .CrossTab(FTv, ATv, V, do Marginals) --> Cross tabulate a vector
//  .Marginals(array) --> Computes array marginals on a 2D table
//  
//  -- Read/Write --
//  .PageHeader --> Writes a page header
//  .WriteTables --> Writes tables to file
//
//Public Attributes:
//  .Args = Scenario arguments array (pointer to passed Args array, or can be 
//                                    changed by setting Perf.Args = XXX)
//  .File = Summary report filename
//  .fp = summary report file handle

//  -- See definition in init --
//  .Info 
//  .Formats
//  .SumArea
//  .Report
//  .Settings
//
//Private Methods
// ... None ...
//

//The Performance dialog box should only be called by the Performance object.
//To invoke the dialog box, call Perf.GetSettings
Dbox "Performance" (Perf)

    init do
        //Use a copy of settings (to allow the user to cancel changes)
        sets = CopyArray(Perf.Settings)
        
    enditem //init
    
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //  Information about scenario and output file
    text "Scenario: " 1,1,10,1
    text "Scenario Name" 11, 1, 79 framed Variable: Perf.Args.Info.Name
    text "Output: " 1, 3, 10
    text "Report filename" 11, 3, 79, 1  framed variable: Perf.File
    
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Checkboxes for reports

    //********BASIC REPORTS
	frame "Basic Reports" 1, 5, 90, 28.5 Prompt: "Basic Reports:"

	checkbox "Title Page" 3, 7, 35, 1 
        Variable: sets.Report.[RPT Title Page]
    checkbox "Input Files and Parameters" 3, 8.5, 35, 1 
        Variable: sets.Report.[RPT Files]
    checkbox "Socioeconomic Data Summary" 3, 10, 35, 1 
        Variable: sets.Report.[RPT Socioeconomic Data]
    checkbox "Highway Network Summary*" 3, 11.5, 35, 1 
        Variable: sets.Report.[RPT Highway Network Summary]
    checkbox "Transit Network Summary*" 3, 13, 35, 1 
        Variable: sets.Report.[RPT Transit Network Summary]
    
    //Select all or none in this category
    button "All" 3, 15, 5, 1 do
        Perf.SetAllReports(True, sets, "basic")
    enditem
	
    button "None" 10, same, 5, 1 do
        Perf.SetAllReports(False, sets, "basic")
    enditem
    
    //********PERFORMANCE REPORTS
	frame "Performance Reports" 45.8, 5, 45.2, 28.5  
        Prompt: "Performance Reports:"
	checkbox "Transit Assignment Summary" 47, 13, 35, 1 
        Variable: sets.Report.[RPT Transit Assignment]
	checkbox "Time Periods and Loading Factors" 47, 14.5, 35, 1 
        Variable: sets.Report.[RPT Time Periods & Loading Factors]
    checkbox "Assigned Trip Summary" 47, 16, 35, 1 
        Variable: sets.Report.[RPT Assigned Trip Summary]
    checkbox "ActivitySim - Person Travel Summary" 47, 17.5, 35, 1 
        Variable: sets.Report.[RPT ASIM Summary Report]
    checkbox "Daily Assignment Summary*" 47, 19, 35, 1 
        Variable: sets.Report.[RPT DY Vehicle Assignment]
        
    text "Peak: " 50, 20.5, 9, 1 
    checkbox "AM" after, same, 5, 1 
        Variable: sets.Report.[RPT AM Vehicle Assignment]
    checkbox "PM"  after, same, 5, 1 
        Variable: sets.Report.[RPT PM Vehicle Assignment]
        
    text "Off-Peak: " 50, 22, 9, 1 
    checkbox "MD" after, same, 5, 1 
        Variable: sets.Report.[RPT MD Vehicle Assignment]
    checkbox "EV" after, same, 5, 1 
        Variable: sets.Report.[RPT EV Vehicle Assignment]
    checkbox "EA" after, same, 5, 1 
        Variable: sets.Report.[RPT EA Vehicle Assignment]
        
        
    //Select all or none in this category
	button "All" 48, 24, 5, 1 do
        Perf.SetAllReports(True, sets, "perf")
    enditem
	
	button "None" 55, same, 5, 1 do
        Perf.SetAllReports(False, sets, "perf")
    enditem
    
    //********VALIDATION REPORTS
	frame "Validation Reports" 1, 16.5, 45, 17 Prompt: "Validation Reports:"

    checkbox "Daily Vehicle Validation Summary" 3, 18, 35, 1 
        Variable: sets.Report.[RPT DY Vehicle Validation]
        
    text "Peak: " 5, 19.5, 9, 1 
    checkbox "AM" after, same, 5, 1 
        Variable: sets.Report.[RPT AM Vehicle Validation]
    checkbox "PM"  after, same, 5, 1 
        Variable: sets.Report.[RPT PM Vehicle Validation]
        
    text "Off-Peak: " 5, 21, 9, 1 
    checkbox "MD" after, same, 5, 1 
        Variable: sets.Report.[RPT MD Vehicle Validation]
    checkbox "EV" after, same, 5, 1 
        Variable: sets.Report.[RPT EV Vehicle Validation]
    checkbox "EA" after, same, 5, 1 
        Variable: sets.Report.[RPT EA Vehicle Validation]
        
    text "Auto/Truck: " 5, 22.5, 12, 1
    checkbox "Auto+L.Trk" after, same, 10, 1
        Variable: sets.Report.[RPT Auto Light Truck Validation]
    checkbox "Med+Heavy Trk" after, same, 10, 1
        Variable: sets.Report.[RPT Truck Validation]
    
    text "Truck Class: " 5, 24, 12, 1
    checkbox "Med. Trk" after, same, 10, 1
        Variable: sets.Report.[RPT Medium Truck Validation]
    checkbox "Heavy Trk" after, same, 10, 1
        Variable: sets.Report.[RPT Heavy Truck Validation]
        
    checkbox "Screenline Summary (All Vehicles)" 3, 25.5, 35, 1
        Variable: sets.Report.[RPT Screenline]
    text "Auto/Truck: " 5, 27, 12, 1
    checkbox "Auto+L.Trk" after, same, 10, 1
        Variable: sets.Report.[RPT Auto Light Truck Screenline]
    checkbox "Med+Heavy Trk" after, same, 10, 1
        Variable: sets.Report.[RPT Truck Screenline]
    
    text "Truck Class: " 5, 28.5, 12, 1
    checkbox "Med. Trk" after, same, 10, 1
        Variable: sets.Report.[RPT Medium Truck Screenline]
    checkbox "Heavy Trk" after, same, 10, 1
        Variable: sets.Report.[RPT Heavy Truck Screenline]
  
    checkbox "CV Model Validation Report" 3, 30, 35, 1
        Variable: sets.Report.[RPT CV Model Validation]
        
    //Select all or none in this category
    button "All" 3, 32, 5, 1 do
        Perf.SetAllReports(True, sets, "validation")
    enditem
	
    button "None" 10, 32, 5, 1 do
        Perf.SetAllReports(False, sets, "validation")
    enditem
    
    //*********SUMMARY AREA SELECTION
	frame "Create Reports For" 1, 34.5, 45, 11 Prompt: "* Create Reports For:"
    
	checkbox "Entire Model" 3, 36.5,   15, 1 
        Variable: sets.SumArea.[Entire Model]
	checkbox "Detroit" 3, 38, 15, 1 
        Variable: sets.SumArea.[Detroit]
	checkbox "Wayne" 3, 39.5, 15, 1 
        Variable: sets.SumArea.[Wayne]
	checkbox "Oakland" 3, 41,   15, 1  
        Variable: sets.SumArea.[Oakland]
	checkbox "Macomb" 3, 42.5, 15, 1 
        Variable: sets.SumArea.[Macomb]
        
	checkbox "Washtenaw" 22, 38, 15, 1 
        Variable: sets.SumArea.[Washtenaw]
	checkbox "Monroe"     22, 39.5,   15, 1 
        Variable: sets.SumArea.[Monroe]
	checkbox "St. Clair"     22, 41,   15, 1 
        Variable: sets.SumArea.[St Clair]
    checkbox "Livingston"     22, 42.5,   15, 1 
        Variable: sets.SumArea.[Livingston]
        
	//checkbox "Custom"     22, 35,   15, 1 
    //    Variable: sets.SumArea.[Custom]
        

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
// Global Buttons

    //*********REPORT SELECTION
	frame "Global Selection" 45.8, 34.5, 45.2, 8 Prompt: "Global Selection:"
	frame "Global Separator" 45.8, 34.5, 45.2, 4 Prompt: "Global Selection:"
	button "Select All Reports" 50, 36.3, 17, 1.5 do
        Perf.SetAllReports(True, sets)
    enditem
    
	button "Select No Reports" 70, 36.3, 17, 1.5 do
        Perf.SetAllReports(False, sets)
    enditem
    
	button "Select All Areas" 50, 39.8, 17, 1.5 do
        Perf.SetAllAreas(True, sets)
    enditem
    
	button "Select No Areas" 70, 39.8, 17, 1.5 do
        Perf.SetAllAreas(False, sets)
    enditem

    //**********OK OR CANCEL
    //button "Go" 58, 34, 15, 2 default Prompt: OkText do
	button "Go" 58, 43.5, 15, 2 default Prompt: "OK" do
        Perf.Settings = CopyArray(sets)     //Commit changes to the Perf object
        SaveArray(sets, Perf.SavedSettings) //Save settings for next time
        Return(True)
    enditem
    
    button "Cancel" 75, same, 15, 2 cancel do
        return()
    enditem

EndDbox

Class "Performance"  //StartClass

    init do
    //StartMethod
        shared UT

        t = SplitPath(GetInterface())
        ui_dir = t[1] + t[2]
    
        //Run SetArgs() to set scenario.
        self.Args = null
        
        //Allow Args2 (if needed for detailed Args when using Caliper Args format)
        self.Args2 = null

        //Report assumes the facility and area type field names are "FT" and "AT"
        // - use a formula to set if needed. 
        // - null FTFormula or ATFormula will assume FT and/or AT already exist
        self.Info.FTFormula = "if Left(NFC_FLAG,1) = 'R' then 11 else if NFC_FLAG = 'FCD' then 12 else NFC"
        self.Info.ATFormula = "AREA_TYPE"
        
        //FT values
        self.Info.FT = {{"Interstate Fwy",         1},
                        {"Other Fwy",              2},
                        {"Principal Arterial",     3},
                        {"Minor Arterial",         4},
                        {"Major Collector",        5},
                        {"Minor Collector",        6},
                        {"Local Road",             7},
                        {"Uncertified Road",       9},
                        {"Ramp",                   11},
                        {"Collector Distributor",  12},
                        
                        {"Centroid Connector",     99}}
        
        //AT Values
        self.Info.AT = {{"UrbanBusiness", 1},
                        {"UrbanFringe",   2},
                        {"Urban",         3},
                        {"Suburban",      4},
                        {"Rural",         5}}
                        
        //County Values (indexed directly)
        self.Info.Counties = {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw",
                              "Monroe", "St Clair", "Livingston"}
							  
		//Class Values
		self.Info.Class = {"DRIVEALONE", "SHARED2", "SHARED3", "Light Truck", "Medium Truck", "Heavy Truck"}

        //Default format settings
        self.Formats = null
        self.Formats.Filetype = "html" //html or excel - overridden by filename
		
        //Global Formats
        self.Formats.NumberFormats = "*,."
        self.Formats.LogoFile = ui_dir + "bmp\\report_logo.png"
        self.Formats.LogoH = '91' //W and H must be strings
        self.Formats.LogoW = '200'
		
        //html formats
        self.Formats.TablesPerPage = 2
        self.Formats.html.CSSFile = ui_dir + "Style.css"
        self.Formats.html.ScriptFile = ui_dir + "ReportScript.txt"
        
        //Default chart settings
        self.ChartCount = 0 //Chart count for re-drawing in pin area
        self.chartDefaults = null
        self.chartDefaults.Type = "bar"
        self.chartDefaults.Width = 600
        self.chartDefaults.Height = 300
        self.chartDefaults.Colors = {{91, 155, 213}, {237, 125, 49}, {255, 192, 0}, {68, 114, 196}, {112, 173, 71}}
        //Repeat colors to allow large sets 
        orig = CopyArray(self.chartDefaults.Colors)
        for ii = 1 to 5 do
            self.chartDefaults.Colors = self.chartDefaults.Colors + CopyArray(orig)
        end
		
        //excel formats
        h1 = null
        h1.Font.Size = 14
        h1.Font.Bold = True
        
        h2 = null
        h2.Font.Size = 12
        h2.Font.Italic = True

        bluetext = null
        bluetext.Font.Size = 10
        bluetext.Font.Color = self.ExcelRGB(54, 96, 146)
        
        greytext = null
        greytext.Font.Size = 10
        greytext.Font.Color = self.ExcelRGB(54, 96, 146)  
        
        value = null
        value.Font.Size = 10
        value.Font.Color = self.ExcelHEX('000000')
        value.Borders.LineStyle = 1 //xlContinous
        value.Borders.Weight = 2 //xlThin
        value.Borders.ThemeColor = 2 //dark grey
        
        bold = CopyArray(value)
        bold.Font.Bold = True
        
        self.Formats.excel.Styles.h1 = h1
        self.Formats.excel.Styles.h2 = h2
        self.Formats.excel.Styles.bluetext = bluetext
        self.Formats.excel.Styles.greytext = greytext
        self.Formats.excel.Styles.value = value
        self.Formats.excel.Styles.bold = bold
        
        self.Formats.excel.LabelWidth = 150  //in pixels, same as html to be consistent if passed
        self.Formats.excel.DataWidth = 75  //by the macros themselves
        self.Formats.excel.TablesPerPage = 2
        
        self.ExcelRow = 1
        self.ExcelCol = 1 //to keep track of row and columns while writing tables
        
        //Define summary areas
        self.SumArea = null
        
        self.SumArea.[Entire Model].Field = null       //Field for summary area selection (null for all records)
        self.SumArea.[Entire Model].Value = null       //Value in field for summary area selection (null for all records) 
        self.SumArea.[Entire Model].Network = True   //Run query for Network-based reports?
        self.SumArea.[Entire Model].Zones = True     //Run query for TAZ-based reports?
        self.SumArea.[Entire Model].Active = True    //Default status (overridden by settings)
        
        self.SumArea.[Detroit].Field = "County"
        self.SumArea.[Detroit].Value = 1
        self.SumArea.[Detroit].Network = True
        self.SumArea.[Detroit].Zones = True
        self.SumArea.[Detroit].Active = False
        
        self.SumArea.[Wayne].Field = "County"
        self.SumArea.[Wayne].Value = 2
        self.SumArea.[Wayne].Network = True
        self.SumArea.[Wayne].Zones = True
        self.SumArea.[Wayne].Active = False   
        
        self.SumArea.[Oakland].Field = "County"
        self.SumArea.[Oakland].Value = 3
        self.SumArea.[Oakland].Network = True
        self.SumArea.[Oakland].Zones = True
        self.SumArea.[Oakland].Active = False   
        
        self.SumArea.[Macomb].Field = "County"
        self.SumArea.[Macomb].Value = 4
        self.SumArea.[Macomb].Network = True
        self.SumArea.[Macomb].Zones = True
        self.SumArea.[Macomb].Active = False    
        
        self.SumArea.[Washtenaw].Field = "County"
        self.SumArea.[Washtenaw].Value = 5
        self.SumArea.[Washtenaw].Network = True
        self.SumArea.[Washtenaw].Zones = True
        self.SumArea.[Washtenaw].Active = False   
        
        self.SumArea.[Monroe].Field = "County"
        self.SumArea.[Monroe].Value = 6
        self.SumArea.[Monroe].Network = True
        self.SumArea.[Monroe].Zones = True
        self.SumArea.[Monroe].Active = False     
        
        self.SumArea.[St Clair].Field = "County"
        self.SumArea.[St Clair].Value = 7
        self.SumArea.[St Clair].Network = True
        self.SumArea.[St Clair].Zones = True
        self.SumArea.[St Clair].Active = False    
        
        self.SumArea.[Livingston].Field = "County"
        self.SumArea.[Livingston].Value = 8
        self.SumArea.[Livingston].Network = True
        self.SumArea.[Livingston].Zones = True
        self.SumArea.[Livingston].Active = False
        
        //Define reports
        section = 0
        self.Report = null
        self.Report.[RPT Title Page].Contents = "Title Page"  //Name in the table of contents
        self.Report.[RPT Title Page].Anchor = "TitlePage"     //HTML anchor (for linking)
        self.Report.[RPT Title Page].Active = 1               //Default status (overriden by settings)
        self.Report.[RPT Title Page].Section = section              //Report section number
        self.Report.[RPT Title Page].Group = "basic"          //Report group (for on/off buttons)
        self.Report.[RPT Title Page].InGeneral = True
		section = section + 1
                     
        self.Report.[RPT Files].Contents = "Files and Settings"
        self.Report.[RPT Files].Anchor = "Files"
        self.Report.[RPT Files].Active = 1
        self.Report.[RPT Files].Section = section
        self.Report.[RPT Files].Group = "basic"
        self.Report.[RPT Files].InGeneral = False
        section = section + 1
                     
        self.Report.[RPT Highway Network Summary].Contents = "Highway Network Summary"
        self.Report.[RPT Highway Network Summary].Anchor = "Network"
        self.Report.[RPT Highway Network Summary].Active = 1
        self.Report.[RPT Highway Network Summary].Section = section
        self.Report.[RPT Highway Network Summary].Group = "basic"
		self.Report.[RPT Highway Network Summary].InGeneral = True
        section = section + 1
        
        self.Report.[RPT Transit Network Summary].Contents = "Transit Network Summary"
        self.Report.[RPT Transit Network Summary].Anchor = "Routes"
        self.Report.[RPT Transit Network Summary].Active = 1
        self.Report.[RPT Transit Network Summary].Section = section
        self.Report.[RPT Transit Network Summary].Group = "basic"
	    self.Report.[RPT Transit Network Summary].InGeneral = False
        section = section + 1

        self.Report.[RPT Socioeconomic Data].Contents = "RPT Socioeconomic Data"
        self.Report.[RPT Socioeconomic Data].Anchor = "SE"
        self.Report.[RPT Socioeconomic Data].Active = 1
        self.Report.[RPT Socioeconomic Data].Section = section
        self.Report.[RPT Socioeconomic Data].Group = "basic"
        self.Report.[RPT Socioeconomic Data].InGeneral = True
        section = section + 1

        self.Report.[RPT ASIM Summary Report].Contents = "ActivitySim - Person Travel Summary"
        self.Report.[RPT ASIM Summary Report].Anchor = "Trans"
        self.Report.[RPT ASIM Summary Report].Active = 1
        self.Report.[RPT ASIM Summary Report].Section = section
        self.Report.[RPT ASIM Summary Report].Group = "perf"
		self.Report.[RPT ASIM Summary Report].InGeneral = True
        section = section + 1
        
        self.Report.[RPT Transit Assignment].Contents = "Transit Assignment Summary"
        self.Report.[RPT Transit Assignment].Anchor = "Trans"
        self.Report.[RPT Transit Assignment].Active = 1
        self.Report.[RPT Transit Assignment].Section = section
        self.Report.[RPT Transit Assignment].Group = "perf"
		self.Report.[RPT Transit Assignment].InGeneral = True
        section = section + 1
		
		self.Report.[RPT Time Periods & Loading Factors].Contents = "Time Periods & Loading Factors"
        self.Report.[RPT Time Periods & Loading Factors].Anchor = "Trans"
        self.Report.[RPT Time Periods & Loading Factors].Active = 1
        self.Report.[RPT Time Periods & Loading Factors].Section = section
        self.Report.[RPT Time Periods & Loading Factors].Group = "perf"
		self.Report.[RPT Time Periods & Loading Factors].InGeneral = True
        section = section + 1
        
        self.Report.[RPT Assigned Trip Summary].Contents = "Assigned Trip Summary"
        self.Report.[RPT Assigned Trip Summary].Anchor = "Trans"
        self.Report.[RPT Assigned Trip Summary].Active = 1
        self.Report.[RPT Assigned Trip Summary].Section = section
        self.Report.[RPT Assigned Trip Summary].Group = "perf"
		self.Report.[RPT Assigned Trip Summary].InGeneral = True
        section = section + 1
        
        self.Report.[RPT DY Vehicle Assignment].Contents = "Daily Vehicle Assignment Summary"
        self.Report.[RPT DY Vehicle Assignment].Anchor = "Assignment"
        self.Report.[RPT DY Vehicle Assignment].Active = 1
        self.Report.[RPT DY Vehicle Assignment].Section = section
        self.Report.[RPT DY Vehicle Assignment].Group = "perf"
		self.Report.[RPT DY Vehicle Assignment].InGeneral = True
        section = section + 1
        
        self.Report.[RPT AM Vehicle Assignment].Contents = "AM Vehicle Assignment Summary"
        self.Report.[RPT AM Vehicle Assignment].Anchor = "Assignment"
        self.Report.[RPT AM Vehicle Assignment].Active = 1
        self.Report.[RPT AM Vehicle Assignment].Section = section
        self.Report.[RPT AM Vehicle Assignment].Group = "perf"
		self.Report.[RPT AM Vehicle Assignment].InGeneral = True
        section = section + 1
        
        self.Report.[RPT PM Vehicle Assignment].Contents = "PM Vehicle Assignment Summary"
        self.Report.[RPT PM Vehicle Assignment].Anchor = "Assignment"
        self.Report.[RPT PM Vehicle Assignment].Active = 1
        self.Report.[RPT PM Vehicle Assignment].Section = section
        self.Report.[RPT PM Vehicle Assignment].Group = "perf"
		self.Report.[RPT PM Vehicle Assignment].InGeneral = True
        section = section + 1
        ///
        self.Report.[RPT MD Vehicle Assignment].Contents = "MD Vehicle Assignment Summary"
        self.Report.[RPT MD Vehicle Assignment].Anchor = "Assignment"
        self.Report.[RPT MD Vehicle Assignment].Active = 1
        self.Report.[RPT MD Vehicle Assignment].Section = section
        self.Report.[RPT MD Vehicle Assignment].Group = "perf"
		self.Report.[RPT MD Vehicle Assignment].InGeneral = True
        section = section + 1
        
        self.Report.[RPT EV Vehicle Assignment].Contents = "EV Vehicle Assignment Summary"
        self.Report.[RPT EV Vehicle Assignment].Anchor = "Assignment"
        self.Report.[RPT EV Vehicle Assignment].Active = 1
        self.Report.[RPT EV Vehicle Assignment].Section = section
        self.Report.[RPT EV Vehicle Assignment].Group = "perf"
		self.Report.[RPT EV Vehicle Assignment].InGeneral = True
        section = section + 1
        
        self.Report.[RPT EA Vehicle Assignment].Contents = "EA Vehicle Assignment Summary"
        self.Report.[RPT EA Vehicle Assignment].Anchor = "Assignment"
        self.Report.[RPT EA Vehicle Assignment].Active = 1
        self.Report.[RPT EA Vehicle Assignment].Section = section
        self.Report.[RPT EA Vehicle Assignment].Group = "perf"
		self.Report.[RPT EA Vehicle Assignment].InGeneral = True
        section = section + 1
        
        self.Report.[RPT DY Vehicle Validation].Contents = "Vehicle Validation Summary - Daily"
        self.Report.[RPT DY Vehicle Validation].Anchor = "ValidationDY"
        self.Report.[RPT DY Vehicle Validation].Active = 1
        self.Report.[RPT DY Vehicle Validation].Section = section
        self.Report.[RPT DY Vehicle Validation].Group = "validation"
		self.Report.[RPT DY Vehicle Validation].InGeneral = False
        section = section + 1
        
        self.Report.[RPT AM Vehicle Validation].Contents = "Vehicle Validation Summary - AM"
        self.Report.[RPT AM Vehicle Validation].Anchor = "ValidationAM"
        self.Report.[RPT AM Vehicle Validation].Active = 1
        self.Report.[RPT AM Vehicle Validation].Section = section
        self.Report.[RPT AM Vehicle Validation].Group = "validation"
		self.Report.[RPT AM Vehicle Validation].InGeneral = False
        section = section + 1
        
        self.Report.[RPT PM Vehicle Validation].Contents = "Vehicle Validation Summary - PM"
        self.Report.[RPT PM Vehicle Validation].Anchor = "ValidationPM"
        self.Report.[RPT PM Vehicle Validation].Active = 1
        self.Report.[RPT PM Vehicle Validation].Section = section
        self.Report.[RPT PM Vehicle Validation].Group = "validation"
		self.Report.[RPT PM Vehicle Validation].InGeneral = False
        section = section + 1
        
        self.Report.[RPT MD Vehicle Validation].Contents = "Vehicle Validation Summary - MD"
        self.Report.[RPT MD Vehicle Validation].Anchor = "ValidationMD"
        self.Report.[RPT MD Vehicle Validation].Active = 1
        self.Report.[RPT MD Vehicle Validation].Section = section
        self.Report.[RPT MD Vehicle Validation].Group = "validation"
		self.Report.[RPT MD Vehicle Validation].InGeneral = False
        section = section + 1
        
        self.Report.[RPT EV Vehicle Validation].Contents = "Vehicle Validation Summary - EV"
        self.Report.[RPT EV Vehicle Validation].Anchor = "ValidationEV"
        self.Report.[RPT EV Vehicle Validation].Active = 1
        self.Report.[RPT EV Vehicle Validation].Section = section
        self.Report.[RPT EV Vehicle Validation].Group = "validation"
		self.Report.[RPT EV Vehicle Validation].InGeneral = False
        section = section + 1
        
        self.Report.[RPT EA Vehicle Validation].Contents = "Vehicle Validation Summary - EA"
        self.Report.[RPT EA Vehicle Validation].Anchor = "ValidationNT"
        self.Report.[RPT EA Vehicle Validation].Active = 1
        self.Report.[RPT EA Vehicle Validation].Section = section
        self.Report.[RPT EA Vehicle Validation].Group = "validation"
		self.Report.[RPT EA Vehicle Validation].InGeneral = False
        section = section + 1

        self.Report.[RPT Auto Light Truck Validation].Contents = "Light Vehicle (Auto and Light Truck) Validation Summary"
       self.Report.[RPT Auto Light Truck Validation].Anchor = "ValidationAutoLightTruck"
       self.Report.[RPT Auto Light Truck Validation].Active = 1
       self.Report.[RPT Auto Light Truck Validation].Section = section
       self.Report.[RPT Auto Light Truck Validation].Group = "validation"
	self.Report.[RPT Auto Light Truck Validation].InGeneral = False
   		section = section + 1
   		
   		 self.Report.[RPT Truck Validation].Contents = "Truck (Medium plus Heavy) Validation Summary"
       self.Report.[RPT Truck Validation].Anchor = "ValidatonTruck"
       self.Report.[RPT Truck Validation].Active = 1
       self.Report.[RPT Truck Validation].Section = section
       self.Report.[RPT Truck Validation].Group = "validation"
	self.Report.[RPT Truck Validation].InGeneral = False
   		section = section + 1
        
       self.Report.[RPT Medium Truck Validation].Contents = "Medium Truck Validation Summary"
       self.Report.[RPT Medium Truck Validation].Anchor = "ValidatonMediumTruck"
       self.Report.[RPT Medium Truck Validation].Active = 1
       self.Report.[RPT Medium Truck Validation].Section = section
       self.Report.[RPT Medium Truck Validation].Group = "validation"
	self.Report.[RPT Medium Truck Validation].InGeneral = False
   		section = section + 1
        
       self.Report.[RPT Heavy Truck Validation].Contents = "Heavy Truck Validation Summary"
       self.Report.[RPT Heavy Truck Validation].Anchor = "ValidatonHeavyTruck"
       self.Report.[RPT Heavy Truck Validation].Active = 1
       self.Report.[RPT Heavy Truck Validation].Section = section
       self.Report.[RPT Heavy Truck Validation].Group = "validation"
      	self.Report.[RPT Heavy Truck Validation].InGeneral = False
        section = section + 1
        
        self.Report.[RPT Screenline].Contents = "Screenline Validation Summary"
        self.Report.[RPT Screenline].Anchor = "Screenline"
        self.Report.[RPT Screenline].Active = 1
        self.Report.[RPT Screenline].Section = section
        self.Report.[RPT Screenline].Group = "validation"
		self.Report.[RPT Screenline].InGeneral = False
        section = section + 1
        
        self.Report.[RPT Auto Light Truck Screenline].Contents = "Light Vehicle (Auto and Light Truck) Screenline Validation Summary"
        self.Report.[RPT Auto Light Truck Screenline].Anchor = "AutoLightTruckScreenline"
        self.Report.[RPT Auto Light Truck Screenline].Active = 1
        self.Report.[RPT Auto Light Truck Screenline].Section = section
        self.Report.[RPT Auto Light Truck Screenline].Group = "validation"
	    self.Report.[RPT Auto Light Truck Screenline].InGeneral = False
   		section = section + 1
        
        self.Report.[RPT Truck Screenline].Contents = "Truck (Medium and Heavy) Screenline Validation Summary"
        self.Report.[RPT Truck Screenline].Anchor = "TruckScreenline"
        self.Report.[RPT Truck Screenline].Active = 1
        self.Report.[RPT Truck Screenline].Section = section
        self.Report.[RPT Truck Screenline].Group = "validation"
	    self.Report.[RPT Truck Screenline].InGeneral = False
   		section = section + 1
        
        self.Report.[RPT Medium Truck Screenline].Contents = "Medium Truck Screenline Validation Summary"
       self.Report.[RPT Medium Truck Screenline].Anchor = "MediumTruckScreenline"
       self.Report.[RPT Medium Truck Screenline].Active = 1
       self.Report.[RPT Medium Truck Screenline].Section = section
       self.Report.[RPT Medium Truck Screenline].Group = "validation"
	    self.Report.[RPT Medium Truck Screenline].InGeneral = False
   		section = section + 1
        
       self.Report.[RPT Heavy Truck Screenline].Contents = "Heavy Truck Screenline Validation Summary"
       self.Report.[RPT Heavy Truck Screenline].Anchor = "HeavyTruckScreenline"
       self.Report.[RPT Heavy Truck Screenline].Active = 1
       self.Report.[RPT Heavy Truck Screenline].Section = section
       self.Report.[RPT Heavy Truck Screenline].Group = "validation"
	   self.Report.[RPT Heavy Truck Screenline].InGeneral = False
   		section = section + 1

        self.Report.[RPT CV Model Validation].Contents = "CV Model Validation Spreadsheet"
        self.Report.[RPT CV Model Validation].Anchor = "CVModel"
        self.Report.[RPT CV Model Validation].Active = 1
        self.Report.[RPT CV Model Validation].Section = section
        self.Report.[RPT CV Model Validation].Group = "validation"
	    self.Report.[RPT CV Model Validation].InGeneral = False
        
        
        // ---------------------------------------------------------------------
        // the remainder should rarely be changed
		
        //Create default settings
        //1-Attempt to read from default settings file
        self.SavedSettings = ui_dir + "PerfSettings.arr"
        if GetFileInfo(self.SavedSettings) != null then 
            sets = LoadArray(self.SavedSettings)
        else 
            sets = null

        //2-read from Report settings above
        //Settings in the file override the defaults
        self.Settings = null
        for i = 1 to self.Report.Length do
            Key = self.Report[i][1] //looping through Report.*
            Val = self.Report[i][2]
            if FindOption(sets, "Report") != null and FindOption(sets.Report, Key) != null then 
                self.Settings.Report.(Key) = sets.Report.(Key)
            else
                self.Settings.Report.(Key) = Val.Active
                
            Key = null  Val = null //Set to null to prevent array confusion
        end
        for i = 1 to self.SumArea.Length do
            Key = self.SumArea[i][1] //looping through SumArea.*
            Val = self.SumArea[i][2]
            
            if FindOption(sets, "SumArea") != null and FindOption(sets.SumArea, Key) != null then 
                self.Settings.SumArea.(Key) = sets.SumArea.(Key)
            else
                self.Settings.SumArea.(Key) = 1 // TODO: use proper options array --> Val.Active
            
            Key = null  Val = null //Set to null to prevent array confusion
        end
        
        //Default to page 1, first table
        self.page = 1
        self.table = 1
        
        // File handler
		self.fp = null
    enditem //init
    //EndMethod
    
    //Calculate FT based on formula
    Macro "CalcNetFields" (lyr) do
    
        if self.Info.FTFormula != null then do
            CreateExpression(lyr, "FT", self.Info.FTFormula, )
        end
        
        if self.Info.ATFormula != null then do
            CreateExpression(lyr, "AT", self.Info.ATFormula, )
        end
    
    enditem //EndMethod
    
    //Update the Perf object to use a new set of scenario Args
    Macro "SetArgs" (Args) do
        self.Args = Args
		scen_name = self.Args.Info.Name
		
        //Identify default report filename
		t = SplitPath(self.Args.[Detailed Summary Report])
        self.File = t[1] + t[2] + t[3] + t[4] //Main detailed report
		t = SplitPath(self.Args.[Summary Report])
        self.File2 = t[1] + t[2] + t[3] + t[4] //Report with reduced detail
        
        //Identify report filetype
        t = SplitPath(self.File)
        if t[4] = '.html' or t[4] = '.htm' then 
            self.Formats.Filetype = 'html'
        else if t[4] = '.xls' or t[4] = '.xlsx' or t[4] = '.xlsm' then
            self.Formats.Filetype = 'excel'
        
    EndItem
    //EndMethod
    
    //Get scenario settings from a dialog box
    Macro "GetSettings" do
        Return(RunDbox("Performance", self))
    enditem
    //EndMethod
    
    //Activate or de-activate all reports
    Macro "SetAllReports" (val, sets, group) do
    //val = True for all on, False for all off
    //sets = Settings array to use, or null to change performance report object
    //group = null for all reports, group for only reports in a specific group
    //
    //NOTE: If the sets array is passed, the passed array is modified directly
        
        //Use passed settings, or reference Perf.Settings
        if sets = null then sets = self.Settings
        status = if val then 1 else 0
        for i = 1 to sets.Report.Length do
            k = sets.Report[i][1]
            if (group = null or Lower(self.Report.(k).Group) = Lower(group)) and  Lower(self.Report.(k).Group) != 'title' then 
                sets.Report[i][2] = status
        end
    enditem
    //EndMethod
    
    //Activate or de-activate all areas
    Macro "SetAllAreas" (val, sets) do
    //val = True for all on, False for all off
    //sets = Settings array to use, or null to change performance report object
    //
    //NOTE: If the sets array is passed, the passed array is modified directly
    
        //Use passed settings, or reference Perf.Settings
        if sets = null then sets = self.Settings
        status = if val then 1 else 0
        for i = 1 to sets.SumArea.Length do
            sets.SumArea[i][2] = status
        end
    enditem
    //EndMethod

    Macro "CreateReport" do
    
        if !RunMacro("G30 File Close All") then do
            ShowMessage("Performance Report Canceled")
            Return()
        end
        
        //Identify filename from Args array
        //(self.File is set in the init step)
    
        HideDbox()
        
        //Set up the progress bar and TCB
        RunMacro("TCB Init")
        self.canned = null
        progtot = 0
        prognum = 0
        for i = 1 to self.Settings.Report.length do
            Val = self.Settings.Report[i][2]
            if Val then progtot = progtot + 1
            Val = null
        end
        EnableProgressBar("Processing...", 3)
        self.canned = CreateProgressBar("Initializing Report", "False")
        if self.canned then do
            DestroyProgressBar()
            Return()
        end
        
        //Write HTML page headers
		
		scen_name = self.Args.Info.Name
		
        if self.Formats.Filetype = "html" then do
            self.fp1 = self.HTML_Headers(self.File, {[Page Title]:"SEMCOG " + scen_name + " Detailed Summary Report"})
            self.fp2 = self.HTML_Headers(self.File2,{[Page Title]:"SEMCOG " + scen_name + " Summary Report"})
            self.fp = self.fp1 //fp to write to by default. 
        end
        
        else if self.Formats.Filetype = "excel" then do
        
            Throw("Excel file format not supported.")
        
            //Make sure that an Excel file has the correct extension
            t = SplitPath(self.File)
            self.File = t[1] + t[2] + t[3] + ".xlsx"
            
            //OVERWRITE a pre-existing report - the user is not asked, 
            //   so verify overwrite before calling create
            if GetFileInfo(self.File) != null then do
            
                on error do
                    Opts = null
                    Opts.Buttons = "RetryCancel"
                    ans = MessageBox("Cannot write to Summary report file - Maybe it is open?", Opts)
                    if ans = "Retry" then goto DeleteOldSummary
                    //ShowMessage("Cannot write to Summary report file - Close the file and try again")
                    DestroyProgressBar()
                    DisableProgressBar()
                    Return()
                end
                DeleteOldSummary:
                DeleteFile(self.File)
                on error default
            end
            
        
            //Create the Excel COM object
            XL = CreateCOMObject("Excel.Application")
            self.XL = XL
            
            NewBook = XL.Workbooks.Add()
            XL.WindowState = -4140 //xlMinimized
            XL.Visible = True
            //XL.ScreenUpdating = False
            NewBook.Title = "Summary Report"
            NewBook.SaveAs(self.File)
            //NewBook.SaveAs('C:\\HCAOG Model\\Outputs\\Summary.xlsx')
            
            //Identify initial sheets
            dim InitialSheets[XL.ActiveWorkbook.Sheets.Count]
            for i = 1 to XL.ActiveWorkbook.Sheets.Count do
                SHEET = XL.ActiveWorkbook.Sheets[i]
                InitialSheets[i] = SHEET.Name
            end
            
        end //excel
        else do
            Throw("Invalid report file format specified")
        end
        
        //Write selected reports
        for i = 1 to self.Report.length do
            self.CurrentReportName = self.Report[i][1]  //Name of the report
            self.CurrentReport = self.Report[i][2]  //Report options
            if self.Settings.Report.(self.CurrentReportName) then do
                self.canned = UpdateProgressBar(self.Report.(self.CurrentReportName).Contents, r2i(round(prognum/progtot * 100, 0)))
                if self.canned then do
                    DestroyProgressBar()
                    Return()
                end
                prognum = prognum + 1
            
                ret_value = RunMacro(self.CurrentReportName, self)
                if !ret_value then goto quit
                
                //Reset to first page
                self.page = 1
                self.table = 1
                
                self.ExcelRow = 1
                self.ExcelCol = 1
                
                if self.canned then do
                    DestroyProgressBar()
                    Return()
                end
                
            end
        end
        
        //Finish document
        if Lower(self.Formats.Filetype) = "html" then do
            self.HTML_Close()
        end
        else if Lower(self.Formats.Filetype) = "excel" then do
        
            //Delete initial sheets
            for _del = 1 to InitialSheets.length do
                del = InitialSheets[_del]
                for i = 1 to XL.ActiveWorkbook.Sheets.Count do
                    SHEET = XL.ActiveWorkbook.Sheets[i]
                    if del = SHEET.Name then SHEET.Delete()
                end
            end
            
            
            //Activate the first sheet, update the screen, then save and quit
            XL.ActiveWorkbook.Sheets[1].Activate()
            XL.ScreenUpdating = True
            XL.ActiveWorkbook.Save()
            XL.Quit()
            XL = null
            self.XL = null
        
        end
        else do
            Throw("Invalid report file format specified (This error should never be raised)")
        end

        quit:
        DestroyProgressBar()
        DisableProgressBar()
        RunMacro("TCB Closing", ret_value, !ret_value)
        Return(ret_value)
    enditem
    //EndMethod
    
    Macro "HTML_Headers" (filename, InOpts) do
    
        //filename = String filename to create.  Defaults to self.File
        //Opts.[Page Title] = String page title.  Defaults to "Model Summary Report"
        //
        //Returns: file pointer of file created
        
        if filename = null then filename = self.File
        page_title = if InOpts.[Page Title] = null then "Model Summary Report" else InOpts.[Page Title]
        
    
        fp=OpenFile(filename, "w")
        WriteLine(fp,"<!DOCTYPE html>")
        WriteLine(fp,"<html>")
        WriteLine(fp,"<head>")
        WriteLine(fp,"<title>"+page_title+"</title>")
        WriteLine(fp,'<meta charset="UTF-8">')
        WriteLine(fp, '<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>')
        WriteLine(fp, '<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.5.0/Chart.min.js"></script>')
        WriteLine(fp, '<link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/themes/smoothness/jquery-ui.css">')
        WriteLine(fp, '<script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js"></script>')
        
        //Keep charts from resizing
        WriteLine(fp, '<script>')
        WriteLine(fp, '  Chart.defaults.global.responsive = false;')
        WriteLine(fp, '</script>')
        
        WriteLine(fp, "<style type=\"text/css\">")
    
        //Write the CSS Styles
        css_fp = OpenFile(self.Formats.html.CSSFile, "r")
        css_lines = ReadArray(css_fp)
        CloseFile(css_fp)
        for i = 1 to css_lines.length do
            WriteLine(fp, css_lines[i])
        end
        
        WriteLine(fp,"</style>") 
        
        WriteLine(fp,"</head>")
        WriteLine(fp,"<body>")

        //Write the CSS Styles
        jq_fp = OpenFile(self.Formats.html.ScriptFile, "r")
        jq_lines = ReadArray(jq_fp)
        CloseFile(jq_fp)
        for i = 1 to jq_lines.length do
            WriteLine(fp, jq_lines[i])
        end
        
        Return(fp)
    
    enditem
    //EndMethod
    
    Macro "HTML_Close" do
        fp = self.fp
        WriteLine(fp, "</body></html>")
        self.fp = null
        CloseFile(fp)
        fp = null
        
        if self.fp2 != null then do
            fp2 = self.fp2
            WriteLine(fp2, "</body></html>")
            self.fp2 = null
            CloseFile(fp2)
            fp2 = null
        end
        
    
    enditem
    //EndMethod
    
    //Return a list of {name, query, field, value} for active summary areas
    Macro "ActiveAreas" (type, [AllActive]) do
    //Method must be "Network" or "Zones"
    //Optional AllActive if True, return all areas
        r = null
        for i = 1 to self.SumArea.length do
            Key = self.SumArea[i][1]
            Val = self.SumArea[i][2]
            if (self.Settings.SumArea.(Key) or AllActive) and Val.(type) then do
                if Val.Field = null then qry = "Select * Where True = True"
                else qry = "Select * Where " + Val.Field + " = " + String(Val.Value)
                r = r + {{Key, qry, Val.Field, Val.Value}}
            end
        end
        Return(r)
    enditem
    //EndMethod
    
    //Returns an array of 2D arrays of cross-classified vector data
    Macro "CrossTab" (FTv, ATv, V, DoMarginals, InOpts) do
    //FTv = Facility Type vector
    //ATv = Area Type vector
    //V = Vector of values
    //DoMarginals = if True, marginals will be added to the result
    //Opts
    //  array .RowList: List of values to include for rows (defaults to FT values)
    //  array .ColList: List of values to include for columns (defaults to AT values)
    //
        
        //Process Option to retrieve unique row values, or use default (FT)
        fts = null
        if InOpts.RowList != null and TypeOf(InOpts.RowList) = 'array' then do
            dim fts[InOpts.RowList.Length, 2]
            for i = 1 to fts.length do
                fts[i][1] = InOpts.RowList[i]
                fts[i][2] = i
            end
        end
        else fts = self.Info.FT
        
        //Process Option to retrieve unique col values, or use default (AT)
        ats = null
        if InOpts.ColList != null and TypeOf(InOpts.ColList) = 'array' then do
            dim ats[InOpts.ColList.Length, 2]
            for i = 1 to ats.length do
                ats[i][1] = InOpts.ColList[i]
                ats[i][2] = i
            end
        end
        else ats = self.Info.AT
    
        dim r[fts.length, ats.length]
        for i = 1 to fts.length do
            for j = 1 to ats.length do
                ft = fts[i][2]
                at = ats[j][2]
                
                F = if FTv = ft and ATv = at then V else 0
                r[i][j] = VectorStatistic(F, "Sum", )
            end
        end
        
        if DoMarginals then
            r = self.Marginals(r)
            
        Return(r)
    enditem
    //EndMethod
    
    Macro "Marginals" (array) do
        a = CopyArray(array) //Don't modify the input
        n = a.length
        m = a[1].length

        //Get row totals
        for i = 1 to n do
            if a[i].length <> m then 
                Throw("Non-rectangular array - cannot compute marginals")
            s = 0
            for j = 1 to m do
                s = s + nz(a[i][j])
            end
            a[i] = a[i] + {s}
        end
        //Get column totals
        dim s[m+1]
        for i = 1 to n do
            for j = 1 to m+1 do
                s[j] = nz(s[j]) + nz(a[i][j])
            end
        end
        a = a + {s}
        
        //Return updated array
        return(a)
    enditem
    //EndMethod

    Macro "PageHeader" (InOpts)do
    
        if InOpts.ClassName != null then do 
            ClassName = InOpts.ClassName
            ClassString = ' class="' + InOpts.ClassName + '"'
        end else do 
            ClassString = ""
        end
    
        name = self.CurrentReport.Contents
        section = self.CurrentReport.Section
        scen_name = self.Args.Info.Name
        
        fileformat = self.Formats.Filetype
        
        pad = 115 - len(self.CurrentReportName)
        //html format
        if fileformat = "html" then do
            fp = self.fp
            WriteLine(fp,'<h2 id="folder_' + self.CurrentReport.Anchor + '"'+ClassString+'> <span class="folder" cursor="pointer">&#x25b8; </span>' + Trim(Substitute(self.CurrentReportName, "RPT", "", )) + '</h2>')

            WriteLine(fp,'<a name = "' + self.CurrentReport.Anchor + '"></a>')
            WriteLine(fp,'<div id="data_' + self.CurrentReport.Anchor + '" class="indent_h2">')
            
        end //html
        
        //excel format
        else if fileformat = "excel" then do
            XL = self.XL
            sheets = XL.ActiveWorkbook.Sheets
            
            //Add a new tab and header if it is the first page
            if self.page = 1 then do
           
                //Add the new sheet at the end of the workbook
                AfterSheet = XL.ActiveWorkbook.Sheets[XL.ActiveWorkbook.Sheets.Count]
                sheets.Add(null, AfterSheet).Name = name
                XL.ActiveSheet.PageSetup.RightHeader = '&"-,Bold Italic"&14Wichita Area Travel Model - ' + 
                                                        scen_name + Char(10) + '&"-,Regular"&11' +
                                                        self.CurrentReportName + ' - Page ' + i2s(section)+
                                                        "."+ '&P'
            end //if first page then add the tab
            
        end
        
    enditem
    //EndMethod
    
    //Write tables (and now charts) to the currently open report file
    Macro "WriteTables" (TableOptsArray, InOpts) do
    //TableOptsArray is an array of options arrays, with one Opts array for
    //  each table to write:
    //   .Name = Name of Table or chart
    //   .Section1 = Sub section 1 name, or null for no sub section
    //   .Section2 = Sub section 2 name, or null for no sub section
    //   .Footnote = footnote to place at end of table or chart
    //   -- only one of the following should be specified --
    //   .Table = Table options array as specified in WriteTable.
    //   .Chart = Chart options array as specified in DrawChart.
    //
    //Other options (InOpts)
    //  .NoHeader = T/F, skip writing the page header if True
    //  .HeaderClass = "ClassName", applies a class to the page header
    
        TOA = CopyArray(TableOptsArray) //Use a copy of the input opts
        fp = self.fp //quick reference
        
        //Write a Page Header
        if !InOpts.NoHeader then do
            if InOpts.HeaderClass != null then do
                self.PageHeader({"ClassName":InOpts.HeaderClass})
            end else do
                self.PageHeader()
            end
        end
        
        //Write tables, with section/sub-section logic
        s1_name = null
        s1_anchor = self.CurrentReport.Anchor + "_MAIN"
        s2_name = null
        for OP in TOA do
        
            //Sub-header 1
            if OP.Section1 != s1_name then do
                //end existing subheader sections if needed
                if s2_name != null then do
                    WriteLine(fp, '</div>')
                    s2_name = null
                end
                if s1_name != null then do
                    WriteLine(fp, "</div>")
                    s2_name = null
                end
                
                //Start new Section 2 (h3)
                if OP.Section1 != null then do
                    s1_name = OP.Section1
                    s1_anchor = self.CurrentReport.Anchor + "_" + Substitute(s1_name, " ", "_", )
                    WriteLine(fp, '<h3 id="folder_'+s1_anchor+'"><span class="folder" cursor="pointer">&#x25b8; </span>')
                    WriteLine(fp, '<a class="clipbd_all"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24">')
                    WriteLine(fp, '<path path="#6D6D6D" fill="#6D6D6D" d="M19 2c-1.229 0-2.18-1.084-3-2h-8c-.82.916-1.771 2-3 2h-3v22h20v-22h-3zm-7 0c.552 0 1 .448 1 1s-.448 1-1 1-1-.448-1-1 .448-1 1-1zm8 20h-3.824c1.377-1.103 2.751-2.51')
                    WriteLine(fp, '3.824-3.865v3.865zm0-8.457c0 4.107-6 2.457-6 2.457s1.518 6-2.638 6h-7.362v-18h4l2.102 2h3.898l2-2h4v9.543z"/></svg></a>')
                    WriteLine(fp, s1_name+'</h3>')
                    WriteLine(fp, '<div class="indent_h3" id="data_'+s1_anchor+'">')
                end else s1_anchor = self.CurrentReport.Anchor + "_MAIN"
            end //subheader 1
            
            //Sub-header 2
            if OP.Section2 != s2_name then do
                
                //end existing subheader 2 sections if needed
                if s2_name != null then do
                    WriteLine(fp, '</div>')
                    s2_name = null
                end
                
                //Start new h4 section
                if OP.Section2 != null then do
                    s2_name = OP.Section2
                    s2_anchor = s1_anchor + "_" + Substitute(s2_name, " ", "_", )
                    WriteLine(fp, '<h4 id="folder_'+s2_anchor+'"><span class="folder" cursor="pointer">&#x25b8; </span>')
                    WriteLine(fp, '<a class="clipbd_all"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24">')
                    WriteLine(fp, '<path path="#6D6D6D" fill="#6D6D6D" d="M19 2c-1.229 0-2.18-1.084-3-2h-8c-.82.916-1.771 2-3 2h-3v22h20v-22h-3zm-7 0c.552 0 1 .448 1 1s-.448 1-1 1-1-.448-1-1 .448-1 1-1zm8 20h-3.824c1.377-1.103 2.751-2.51')
                    WriteLine(fp, '3.824-3.865v3.865zm0-8.457c0 4.107-6 2.457-6 2.457s1.518 6-2.638 6h-7.362v-18h4l2.102 2h3.898l2-2h4v9.543z"/></svg></a>')
                    WriteLine(fp, s2_name+'</h4>')
                    WriteLine(fp, '<div class="indent_h4" id="data_'+s2_anchor+'">')
                end
            end //subheader 2
            

            //Write the table or chart
            WriteLine(fp, "<div>")
            WriteLine(fp, '<h5><span class="pin">&#x1F4CC;&#xFE0E;&nbsp;</span>')
            WriteLine(fp, '<a class="clipbd"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24">')
            WriteLine(fp, '<path path="#6D6D6D" fill="#6D6D6D" d="M19 2c-1.229 0-2.18-1.084-3-2h-8c-.82.916-1.771 2-3 2h-3v22h20v-22h-3zm-7 0c.552 0 1 .448 1 1s-.448 1-1 1-1-.448-1-1 .448-1 1-1zm8 20h-3.824c1.377-1.103 2.751-2.51')
            WriteLine(fp, '3.824-3.865v3.865zm0-8.457c0 4.107-6 2.457-6 2.457s1.518 6-2.638 6h-7.362v-18h4l2.102 2h3.898l2-2h4v9.543z"/></svg></a>')
            WriteLine(fp, OP.Name+'</h5>')
            if OP.Table != null then do
                self.WriteTable(OP.Table)
            end else if OP.Chart != null then do
                self.DrawChart(OP.Chart)
            end
            if OP.Footnote != null then 
                WriteLine(fp, '<div class="footnote">'+OP.Footnote+"</div>")
            WriteLine(fp, "</div>")
            
        end //loop over tables
        
        //End Sections
        if s2_name != null then WriteLine(fp, '</div>')
        if s1_name != null then WriteLine(fp, '</div>')
        if !InOpts.NoHeader then WriteLine(fp, "</div>") //end main section 
    
    enditem //EndMethod - WriteTables
        
    //Write an individual table
    Macro "WriteTable" (TableOpts) do
    //TableOpts Values
    // .RowNames = Table Row Names (defaults to FT names)
    // .ColNames = Table column names (defaults to AT names) 
    //             - length must be cols or cols+1 to also include column name for row labels
    // .TableData = rows x columns array of string or numeric data to write to a table
    // .Formats = string to format all table data, or array of format strings matching TableData dimensions
    // .Class = Table HTML class value (defaults to "dataframe")
    // .TableStyle = stlye string to apply to table
    // .CellStyles = Array of style strings to apply to each cell
    
        shared UT
        TO = CopyArray(TableOpts) //Use a copy of the input opts
        fp = self.fp //quick reference
        
        //!!! TODO - better error checking of malformed input !!!
        
        // *** Some option processing ***
        //ColNames - set default, add first item as blank if needed
        if TO.ColNames = null then TO.ColNames = UT.Keys(self.Info.AT)+{"Total"}
        if TO.ColNames.length = TO.TableData[1].length then TO.ColNames = {''}+TO.ColNames
        
        //CellStyles: add first column (labels) to blank if needed
        if TypeOf(TO.CellStyles) = 'array' then do
            CellStyles = CopyArray(TO.CellStyles)
            if CellStyles[1].length = TO.TableData[1].length then do
                for ii = 1 to CellStyles.length do
                    CellStyles[ii] = {} + CellStyles[ii]
                end
            end
        end 
        else CellStyles = null
        
        
        //RowNames - set default
        if TO.RowNames = null then TO.RowNames = UT.Keys(self.Info.FT)+{"Total"}
        
        //Process number formats
        WriteData = CopyArray(TO.TableData)
        for ii = 1 to WriteData.length do
            for jj = 1 to WriteData[ii].length do
                //Load format string or array.  Use default for null values
                if TO.Formats = null then fmt = self.Formats.NumberFormats
                else if (TypeOf(TO.Formats) = 'array' and TypeOf(TO.Formats[1]) = 'array') then fmt = TO.Formats[ii][jj] 
                else if (TypeOf(TO.Formats) = 'array' and TypeOf(TO.Formats[1]) = 'string') then fmt = TO.Formats[jj]
                else fmt = TO.Formats
                
                
                /*
                fmt = if TO.Formats = null then self.Formats.NumberFormats
                    else if (TypeOf(TO.Formats) = 'array' and TypeOf(TO.Formats[1] = 'array'))then TO.Formats[ii][jj] 
                    else if (TypeOf(TO.Formats) = 'array' and TypeOf(TO.Formats[1] = 'string')) then TO.Formats[jj]
                    else TO.Formats
                    
                */
                if fmt = null then fmt = self.Formats.NumberFormats
                
                //Perform conversion
                if TypeOf(WriteData[ii][jj]) = 'array' then 
                    WriteData[ii][jj] = self.ArrayString(WriteData[ii][jj])
                else if TypeOf(WriteData[ii][jj]) != 'string' then
                    WriteData[ii][jj] = Format(WriteData[ii][jj], fmt)
            end
            //Add row labels
            if TO.RowNames.length >= ii then do
                //InsertArrayElements(WriteData[ii], , {TO.RowNames[ii]})
                WriteData[ii] = {TO.RowNames[ii]} + WriteData[ii]
            end
        end
        
        //write the table
        cls = if TO.Class = null then ' class="dataframe"' else ' class="'+TO.Class+'"'
        sty = if TO.TableStyle = null then null else ' style="'+TO.TableStyle+'"'
        WriteLine(fp, '<table'+ cls + sty + '>')
        
        //Header row
        WriteLine(fp, '  <tr>')
        for t in TO.ColNames do
            WriteLine(fp, '    <th>'+t+'</th>')
        end
        WriteLine(fp, '  </tr>')
        
        //Data (includes row names)
        for ii = 1 to WriteData.length do
            WriteLine(fp, '  <tr>')
            for jj = 1 to WriteData[ii].length do
                td_sty = if CellStyles = null then null else ' style="'+CellStyles[ii][jj]+'"'
                WriteLine(fp, '    <td'+td_sty+'>'+WriteData[ii][jj]+'</td>')
            end
            WriteLine(fp, '  </tr>')
        end
        
        //end the table
        WriteLine(fp, '</table>')
    
    enditem //EndMethod - WriteTable
        
    //Reads an view and creates a table array for writing
    Macro "ViewToTable" (vw, InOpts) do
    //InOpts.Marginals = True to compute row and column totals
    //InOpts.Percents = True to compute percentages
    //InOpts.SortRows = Sorted array of row headers (non-included headers will not be sorted last)
    //InOpts.Transpose = Transpose the data before writing
    
        //this will hold the table (for WriteTable)
        Table = null
    
        //List of fields, for ColHeader
        FieldNames = GetFields(vw, "All")
        FieldNames = FieldNames[1]
        
        Table.ColNames = FieldNames
        
        //If sorting, add a new sort field (this will not be included in the table)
        if InOpts.SortRows != null then do
            sort_arr = InOpts.SortRows
            //if FN = arr[1] then 1 else if FN = arr[2] then 2 
            sort_fld = FieldNames[1]
            exp = null
            for ii = 1 to sort_arr.length do
                sort_val = sort_arr[ii]
                if TypeOf(sort_val) != 'string' then sort_val = String(sort_val)
                exp = exp + 'if '+sort_fld+' = "'+sort_val+'" then ' + String(ii) + ' else '
            end
            //Final else
            exp = exp + '999'
            sort_expr = CreateExpression(vw, "SortBy", exp, )
        
            SortOpts = {{"Sort Order", {{sort_expr, "Ascending"}}}}
        
        end else do
            SortOpts = null
        end
        
        //Put first field in RowNames, remove from remaining fields to be in data
        Table.RowNames = V2A(GetDataVector(vw+"|", FieldNames[1], SortOpts))
        FieldNames = ExcludeArrayElements(FieldNames, 1, 1)
    
        Vs = GetDataVectors(vw+"|", FieldNames, SortOpts)
        for ii = 1 to Vs.length do
            Vs[ii] = V2A(Vs[ii])
        end
        
        //Remove Sort expression now that it's no longer needed
        if InOpts.SortRows != null then do
            DestroyExpression(vw+"."+sort_expr)
        end
        
        Vs = TransposeArray(Vs)
        
        //Add marginals if enabled
        if InOpts.Marginals then do
            Vs = self.Marginals(Vs)
            Table.ColNames = Table.ColNames + {"Total"}
            Table.RowNames = Table.RowNames + {"Total"}
        end
        
        //Compute percentages if enabled
        if InOpts.Percents then do
        
            //Get sum for each row
            totals = null
            for ii = 1 to Vs.length do
                tot = VectorStatistic(A2V(Vs[ii]), "Sum", )
                //Remove marginal total if calculated
                if InOpts.Marginals then do
                    tot = tot - Vs[ii][Vs[ii].length]
                end
                totals = totals + {tot}
            end
            
            //Divide rows by totals
            for ii = 1 to Vs.length do
                Vs[ii] = V2A(A2V(Vs[ii]) / totals[ii])
            end
            
        
        end
        
        Table.TableData = Vs
        
        
        //If necessary, transpse the data before reporting
        if InOpts.Transpose then do
            T = CopyArray(Table)
            Table.TableData = TransposeArray(T.TableData)
            Table.RowNames = ExcludeArrayElements(T.ColNames, 1, 1)
            Table.ColNames = {}+T.RowNames
            T = null
        end
        
        
        Return(Table)
    
    enditem //EndMethod
        
    //Write a single line as a title/header.
    Macro "WriteTitle" (Text, HLevel) do
    //Text = text to write
    //HLevel = header level to write, or 'b' for bold text (no header)
        
        if TypeOf(Text) != "string" then Return()
    
        if Lower(self.Formats.Filetype) = "html" then do
            fp = self.fp
            if TypeOf(HLevel) = 'string' and Lower(HLevel) = 'b' then 
                h = 'b'
            if TypeOf(HLevel) = "int" or TypeOf(HLevel) = "double" then
                h = String(HLevel)
            if TypeOf(h) != "string" then 
                h = '1'
                
            if h = 'b' then do
                sh = '<b>'
                eh = '</b><br>'
            end
            else do
                sh = '<h'+h+'>'
                eh = '</h'+h+'>'
            end
            
            WriteLine(fp, sh+Text+eh)
        
        end
        else do
            msg = "Unsupported file format requested"
            if TypeOf(self.Formats.Filetype) = "string" then
                msg = msg + " - " + self.Formats.Filetype
            ShowMessage(msg)
        end
    
    EndItem
    //EndMethod
    
    //Draw a chart using Chart.js - requires Chart.js library linked to html file
    Macro "DrawChart" (ChartOpts) do
    //ChartOpts 
    // .CanvasID = ID for canvas (must be kpet unique)
    // .Type = Type of chart (defaults to self.chartDefaults.Type)
    // .Labels = Array of data labels {'v1', 'v2', 'v3'} (ignored for scatter)
    // .Data = Array of data arrays: {{1, 2, 3}, {4, 5, 6}} (must be paired if scatter: {{{1, 2, 3}, {4, 5, 6}}, {{...}, {...}}})
    // .Colors = Array of bar chart colors, each an {rgb} array (defaults to self.chartDefaults.Colors)
    // .Names = Array of dataset names (one for each dataset)  (one for each pair if scatter)
    // .Width = string Chart width (defaults to self.chartDefaults.Width)
    // .Height = string Chart width (self.chartDefaults.Height)
    //
    // -- Optional --
    // .XAxis = string with the X axis name
    // .YAxis = string with the Y axis name
    // .XMax = maximum value to plot
    // .YMax = maximum value to plot
    
        CO = CopyArray(ChartOpts) //Use a copy of the input opts
        fp = self.fp //quick reference
        
        //Defaults
        if CO.Width = null then CO.Width = self.chartDefaults.Width
        if TypeOf(CO.Width) != 'string' then CO.Width = String(CO.Width)
        if CO.Height = null then CO.Height = self.chartDefaults.Height
        if TypeOf(CO.Height) != 'string' then CO.Height = String(CO.Height)
        if CO.Colors = null then CO.Colors = self.chartDefaults.Colors
        if CO.Type = null then CO.Type = self.chartDefaults.Type
        
        WriteLine(fp, '<canvas id="'+CO.CanvasID+'" width="'+CO.Width+'" height="'+CO.Height+'" data-count="'+String(self.ChartCount)+'"></canvas>')
        WriteLine(fp, '<script>')
        WriteLine(fp, 'function dChart'+String(self.ChartCount)+' (canvasID) {')
        WriteLine(fp, 'var ctx = document.getElementById(canvasID);')
        WriteLine(fp, 'var data = {')
        if CO.Type = 'scatter' then do
            js_type = 'line'
            WriteLine(fp, '  datasets: [{')
            for ii = 1 to CO.Data.length do
                WriteLine(fp, '    label: "'+CO.Names[ii]+'",')
                WriteLine(fp, '    backgroundColor: "rgba('+JoinStrings(CO.Colors[ii]+{.4}, ", ")+')",')
                WriteLine(fp, '    borderColor: "rgba('+JoinStrings(CO.Colors[ii]+{1}, ", ")+')",')
                WriteLine(fp, '    borderWidth: 1,')
                WriteLine(fp, '    data: [')
                darr = null
                for jj = 1 to CO.Data[ii][1].length do
                    darr = darr + {'x: '+String(CO.Data[ii][1][jj]) + ', y: '+String(nz(CO.Data[ii][2][jj]))}
                end
                WriteLine(fp, "    {" + JoinStrings(darr, "}, {") + "}")
                
                 //end data and datasets array
                if ii < CO.Data.length then WriteLine(fp, '  ]}, {')
                else WriteLine(fp, "    ]}")
            end //datasets  
        end else do  //non-scatter
            if CO.Type = 'stacked' then js_type = 'bar'
            else js_type = CO.Type
            WriteLine(fp, '  labels: '+self.toJSarr(CO.Labels)+',')
            WriteLine(fp, '  datasets: [')
        
            for ii = 1 to CO.Data.length do
                WriteLine(fp, '  {')
                WriteLine(fp, '    label: "'+CO.Names[ii]+'",')
                WriteLine(fp, '    backgroundColor: "rgba('+JoinStrings(CO.Colors[ii]+{.4}, ", ")+')",')
                WriteLine(fp, '    borderColor: "rgba('+JoinStrings(CO.Colors[ii]+{1}, ", ")+')",')
                WriteLine(fp, '    borderWidth: 1,')
                WriteLine(fp, '    data: '+self.toJSarr(CO.Data[ii]))
                if ii < CO.Data.length then WriteLine(fp, '  },')
                else WriteLine(fp, '  }')
            end
        end
        WriteLine(fp, ']};') //end datasets, data, and line
        
        //Chart Options
        WriteLine(fp, 'var options = {scales: {yAxes: [{}], xAxes: [{}]}};')
        
        //Axis labels
        if CO.XAxis != null then do
            WriteLine(fp, 'options.scales.xAxes[0]["scaleLabel"] = {display: true, labelString: "'+CO.XAxis+'"};')
        end
        if CO.YAxis != null then do
            WriteLine(fp, 'options.scales.yAxes[0]["scaleLabel"] = {display: true, labelString: "'+CO.YAxis+'"};')
        end
        
        //Axis max/min
        if CO.XMax != null then
            WriteLine(fp, 'options.scales.xAxes[0]["ticks"] = {max: '+String(CO.XMax)+'};')
        if CO.YMax != null then
            WriteLine(fp, 'options.scales.yAxes[0]["ticks"] = {max: '+String(CO.YMax)+'};')
        
        //Extended types
        if CO.Type = 'scatter' then do
            WriteLine(fp, 'options.scales.xAxes[0]["type"] = "linear";')
            WriteLine(fp, 'options.scales.xAxes[0]["position"] = "bottom";')
            WriteLine(fp, 'options.showLines = false;')
        end else if CO.Type = 'stacked' then do
            WriteLine(fp, 'options.scales.yAxes[0]["stacked"] = true;')
        end
        
        WriteLine(fp, )
        WriteLine(fp, 'var chart = new Chart (ctx, {type: "'+js_type+'", data: data, options: options});')
        WriteLine(fp, '}')
        WriteLine(fp, 'dChart'+String(self.ChartCount)+'("'+CO.CanvasID+'");')
        WriteLine(fp, '</script>')
        
        self.ChartCount = self.ChartCount + 1
        
    
    enditem //EndMethod - DrawChart
    
    //Turn an array into a JavaScript string for use with DrawChart()
    // No nested arrays!
    Macro "toJSarr" (arr) do
    
        dim newArr[arr.length]
        for ii = 1 to arr.length do
            el = arr[ii]
            if TypeOf(el) = 'string' then 
                el = '"'+el+'"'
            else if TypeOf(el) != 'int' and TypeOf(el) != 'double' then
                Throw("toJSarr only works with strings and numbers.")
            
            newArr[ii] = el
        end
        
        rv = '['+JoinStrings(newArr, ", ")+']'
        Return(rv)
    
    enditem //EndMethod
    
    //Write a single blank line
    Macro "WriteBlank" do
        if Lower(self.Formats.Filetype) = "html" then do
            WriteLine(self.fp, '<br>')
        end
        else do
            msg = "Unsupported file format requested"
            if TypeOf(self.Formats.Filetype) = "string" then
                msg = msg + " - " + self.Formats.Filetype
            ShowMessage(msg)
        end
    EndItem
    //EndMethod
    
    //Convert an array to a formatted string, using recursion to show embedded arrays
	Macro "ArrayString" (InArr) do
		Arr = CopyArray(InArr) //Don't risk modifying the input array
		tmp = "{"
		for i = 1 to Arr.length do
			if TypeOf(Arr[i]) = "string" then do
				tmp = tmp + Arr[i] + ", "
			end
			else if TypeOf(Arr[i]) = "array" then do
				//tmp = tmp + "[subarray], "
                tmp = tmp + self.ArrayString(Arr[i]) + ", "
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
    
    //Write a value to a cell by row and column number, format the cell
    Macro "WriteCell" (row, col, val, InOpts) do
    // Opts:
    //   string .Style = name of style (must be defined in Formats.excel)
    //   array .StyleOR = options array of style format overrides / additions
    
        //Process Input Opts
        if InOpts.Style != null and TypeOf(InOpts.Style) = "string" then
            style = self.Formats.excel.Styles.(InOpts.Style)
        else
            style = null

        if InOpts.StyleOR != null and TypeOf(InOpts.StyleOR) = "array" then
            style_or = InOpts.StyleOR
        else
            style_or = null
            
        //process the format
        frmt = InOpts.Format
        colwid = InOpts.ColWidth
    
        //Write value to cell
        CELL = self.XL.ActiveSheet.Cells[row][col]
        CELL.Value = val
        CELL.NumberFormat = self.ExcelFormat(frmt)
        CELL.ColumnWidth = colwid * 0.14

        //Apply style
        if style != null then
            self.SetProperty(CELL, style)
        if style_or != null then 
            self.SetProperty(CELL, style_or)
    
	enditem
	//EndMethod
    
    //Write an array of values to a row in Excel, format all cells in the row
    Macro "WriteLineXL" (row, col, val, InOpts) do
    // row: Row to write in Excel
    // col: Column to begin writing
    // val: one-dimensional array of values to write
    // Opts:
    //   string .Style = name of style (must be defined in Formats.excel)
    //   array .StyleOR = options array of style format overrides / additions
    
        //Process Input Opts
        if InOpts.Style != null and TypeOf(InOpts.Style) = "string" then
            style = self.Formats.excel.Styles.(InOpts.Style)
        else
            style = null

        if InOpts.StyleOR != null and TypeOf(InOpts.StyleOR) = "array" then
            style_or = InOpts.StyleOR
        else
            style_or = null
            
        //Write values to the row
        SHEET = self.XL.ActiveSheet
        RANGE = SHEET.Range(SHEET.Cells[row][col], 
                SHEET.Cells[row][col-1 + val.length])
        RANGE.Value = val
        
        //Apply style
        if style != null then
            self.SetProperty(RANGE, style)
        if style_or != null then 
            self.SetProperty(RANGE, style_or)
            
        //Apply number format (skip first column)
        if InOpts.Format != null then do
        RANGE = SHEET.Range(SHEET.Cells[row][col+1], 
                SHEET.Cells[row][col-1 + val.length])
            RANGE.NumberFormat = self.ExcelFormat(InOpts.Format)
            

        end //Format
        
        //release XL objects
        SHEET = null
        RANGE = null
    
	enditem
	//EndMethod
    
    //Recursive function to allow setting of object properties using
    //   an Opts array with multiple levels
    //
    Macro "SetProperty" (Obj, InOpts) do
    
        if InOpts != null and TypeOf(InOpts) = 'array' then do
            for _opt = 1 to InOpts.Length do
                key = InOpts[_opt][1]
                val = InOpts[_opt][2]
                
                if val = null or TypeOf(val) != 'array' then do
                
                    Obj.(key) = val
                end //Not an array
                else self.SetProperty(Obj.(key), val)

            end
        end
    
    enditem
    //EndMethod
    
    
    //Convert a hexidecimal color for use in Excel.  The Excel color property
    //  uses a decimal number value in reverse order. This macro takes a standard
    //  hex color value, reverses it, and converts it to decimal format
    //
    //  Any invalid input will silently fail and return black (0).
    Macro "ExcelHEX" (cHex) do

        if cHex = null or TypeOf(cHex) != 'string' then Return(0)
        if Len(cHex) != 6 then Return(0)

        //HEX Lookup
        HLU = {{'0', 0}, {'1', 1}, {'2', 2}, {'3', 3}, {'4', 4}, {'5', 5}, {'6', 6}, 
               {'7', 7}, {'8', 8}, {'9', 9}, {'A', 10}, {'B', 11}, {'C', 12}, 
               {'D', 13}, {'E', 14}, {'F', 15}}

        //Excel seems to work in reverse, so switch the order of the string
        cHex = cHex[5] + cHex[6] + cHex[3] + cHex[4] + cHex[1] + cHex[2]
        
        //Convert the HEX number to a decimal number
        tot = 0
        for ii = 0 to (Len(cHex) - 1) do
            place = Len(cHex) - (ii) //work backwards, 
            digit = cHex[place]      //Getting each digit
            val = HLU.(digit)        //Look up the decimal equivalent
            if val = null then Return(0) //Fail with black on invalid character
            
            tot = tot + val * Pow(16, ii)  //Then multiply by (16^ii)
        end
        
        Return(tot)
        
    enditem
    //EndMethod
    
    Macro "ExcelRGB" (xlR, xlG, xlB) do
    
        Return(Min(Max(nz(xlR), 0), 255) + 
               Min(Max(nz(xlG), 0), 255)*256 + 
               Min(Max(nz(xlB), 0), 255)*256*256)
               
    enditem
     //EndMethod
    
    //Convert a TransCAD Format string to an Excel format string.  This only
    //  works for specific pre-defined format strings - this macro can be
    //  extended to allow additional format strings.
    Macro "ExcelFormat" (TCfmt) do
        
        Formats = null
        Formats.("*,.") = "#,##0"
        Formats.("*0,") = "#,##0"
        Formats.("*0,.") = "#,##0"
        Formats.("*0,.0") = "#,##0.0"
        Formats.("*,0.") = "#,##0"
        Formats.("*0.00") = "#,##0.00"
        Formats.("*,0.00") = "#,##0.00"
        Formats.("*0.0%") = "0.0%"
        Formats.("*0.00%") = "0.00%"
        Formats.("*%0.0") = "0.0%"
 
        if TCfmt<>null then EXfmt = Formats.(TCfmt)

        Return(EXfmt)
        
    enditem
    //EndMethod
    
    Macro "WidthXL" (width) do
    
        Return((width - 5 )/ 7)
        
    enditem
    //EndMethod
    
EndClass


// *****************************************************************************
// Create Title Page********************************************************
Macro "RPT Title Page" (Perf)
    
    shared UT
    shared scen_data_dir

    
    //Loop over two report files if avaialble
    if Perf.fp2 != null then files = {Perf.fp, Perf.fp2} else files = {Perf.fp}
    for _fp = 1 to files.length do
    
        fp = files[_fp]

		// Write the scenario information
		SetCursor("Hourglass")
		WriteLine(fp,'<h1>SEMCOG Summary Report</h1>')
        WriteLine(fp,'<div class="indent_h1">')
        WriteLine(fp,'<div class="titleInfo"><span class="blueText">Scenario Name: </span>' + Perf.Args.Info.Name + '</div>')
		WriteLine(fp,'<div class="titleInfo"><span class="blueText">Input Directory: </span>' + Perf.Args.Info.[Input Directory] + '</div>')
		WriteLine(fp,'<div class="titleInfo"><span class="blueText">Output Directory: </span>' + Perf.Args.Info.[Output Directory] + '</div>')
		WriteLine(fp,'<div class="titleInfo"><span class="blueText">Report File: </span>' + Perf.File + '</div>')
		WriteLine(fp,'<div class="titleInfo"><span class="blueText">Report Created on: </span>' + UT.FormatDate() + '</div>')
		WriteLine(fp,'<div class="titleInfo"><span class="blueText">Scenario Description: </span> '+ Perf.Args.Info.Description +'</div>')
		WriteLine(fp, '</div>')
        
		//Write the table of contents
		WriteLine(fp,'<h2 id="folder_TOC"><span class="folder">&#x25b8; </span>Table of Contents</h2>')
        WriteLine(fp,'<div id="data_TOC" class="indent_h2">')
		WriteLine(fp, '<p class="grey">')
        sec = 1
		for ii = 1 to Perf.Report.length do
			Key = Perf.Report[ii][1]
			Val = Perf.Report[ii][2]
			Set = Perf.Settings.Report.(Key)
            
            if _fp = 1 or Val.InGeneral then do
			
                if Set then WriteLine(fp,'<a href = "#'+Val.Anchor+'">')
                WriteLine(fp, "  " + string(sec - 1) + ". " + Val.Contents)
                if Set then WriteLine(fp,"</a><br>")
                else WriteLine(fp,"<br>")
                
                sec = sec + 1
                
            end
		end
        WriteLine(fp, '</div>')
	end //loop over 2 reports
	
    Return(1)
EndMacro  //End of Title Page Macro

// *****************************************************************************
// Input File Data Summary


Macro "RPT Files" (Perf)
    
    Args = Perf.Args2 //When using the Caliper scenario array format, Args2 contains additional detail
    
	//Define stage name titles
    Titles = {"Initialization and network creation:",
             
             "Skimming:",
             "External and Airport Models:",
             "ActivitySim Model:",
             "Commercial Vehicle Model:",
             
             "Traffic Assignment:",
             "Reporting:"}
	
	Stages = {"INI","SKM", "EXT", "ABM", "CVM", "ASN", "RPT"}
    
    
    DataTypes = {"Output", "Param", "Table"}
    DataHeaders = {"Output", "Parameters", "Tables"} //nice names 
    
    //Create Input Table
    inputs = Args.Input
   
   //write input files
    InTable = null
    InRowNames = null
    for _in = 1 to inputs.length do
        InRowNames = InRowNames + {inputs[_in][1]}
        val = inputs[_in][2].Value
        if TypeOf(val) = "array" then val = Perf.ArrayString(val)
        InTable = InTable + {{val + "<br>"+inputs[_in][2].Desc}}
    end
    
    TB = null
    TB.Section1 = "Input Files"
    TB.Name = null //no table name for inputs
    TB.Table.RowNames = InRowNames
    TB.Table.ColNames = {'Key', 'Value & Description'}
    TB.Table.TableData = InTable
    TB.Table.Class = 'zebra'
    Tables = {CopyArray(TB)}

    //write the outputs, params, tables and dbtables for allstages
    for _stage = 1 to Stages.length do
        stage = Stages[_stage]
        title = Titles[_stage]
        
        for _type = 1 to DataTypes.length do 
            type = DataTypes[_type]
            outputs = Args.(type).(stage) //ouput/params/table for each stage
            if outputs != null then do 
                Table = null
                Rows = null
                for _out = 1 to outputs.length do
                    Rows = Rows + {outputs[_out][1]}
                    val = outputs[_out][2].Value
                    if TypeOf(val) = "array" then val = Perf.ArrayString(val)
                    else if TypeOf(val) != "string" then val = String(val)
                    Table = Table + {{val+'<br>'+outputs[_out][2].Desc}}
                end
                TB = null
                TB.Section1 = Titles[_stage]
                TB.Name = DataHeaders[_type]
                TB.Table.RowNames = CopyArray(Rows)
                TB.Table.ColNames = {'Key', 'Value & Description'}
                TB.Table.TableData = CopyArray(Table)
                TB.Table.Class = 'zebra'
                Tables = Tables + {CopyArray(TB)}
                
            end //output!=null
        end //var
    end //stage
    


    Perf.WriteTables(Tables, )
       
    Return(True)
    

    
EndMacro

// *****************************************************************************
// Highway Network Summary
Macro "RPT Highway Network Summary" (Perf)

    shared UT

    //FT and AT information
    ft_no = UT.Values(Perf.Info.FT)  //Returns a list of numbers only
    at_no = UT.Values(Perf.Info.AT)

    //Summary area - areas = {name, query}
    areas = Perf.ActiveAreas("Network")  //Can be Network or Zones
    
    //Define files
    dbd_file = Perf.Args.[Highway DB]

    //Dimension arrays to hold data: TableXXX[area][ft(row)][at(col)]
    dim TablesCL[areas.length]
    dim TablesLM[areas.length]
    TableGroup = {TablesCL, TablesLM}
    NameGroup = {"Network Centerline Summary", "Network Lane-Mile Summary"}
    
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    SetView(link_lyr)
    
    // ======= Summarize by County =======
    {FTv, COUNTYv, CLv, 
    ABLANESv, BALANESv} = GetDataVectors(link_lyr+"|", 
                          {"FT", "COUNTY", "Length", 
                          "AB_LANES", "BA_LANES"}, )
                          
    //Math
    LANESv = nz(ABLANESv) + nz(BALANESv)
    LMv = CLv*LANESv
                          
    //Compute cross-class with marginals
    Opts = null
    Opts.ColList = V2A(Vector(Perf.Info.Counties.length, "Long", {{"Sequence", 1, 1}}))
    
    dim TablesCounty[2]
    TablesCounty[1] = Perf.CrossTab(FTv, COUNTYv, CLv, True, Opts)
    TablesCounty[2] = Perf.CrossTab(FTv, COUNTYv, LMv, True, Opts)
    
    // ======= loop over summary areas =======
    for _area = 1 to areas.length do
        area_name = areas[_area][1]
        area_qry = areas[_area][2]
        //Do not report disabled links
        setcount = SelectByQuery("SummaryArea", "Several", 
                                 "Select * Where FT > 0", )
        setcount = SelectByQuery("SummaryArea", "Subset", area_qry, )
        //Only summarize if links are selected
        if setcount > 0 then do

            //Load data from view
            {FTv, ATv, CLv, 
            ABLANESv, BALANESv} = GetDataVectors(link_lyr+"|SummaryArea", 
                                  {"FT", "AT", "Length", 
                                  "AB_LANES", "BA_LANES"}, )
                                  
            //Math
            LANESv = nz(ABLANESv) + nz(BALANESv)
            LMv = CLv*LANESv
                                  
            //Compute cross-class with marginals
            TablesCL[_area] = Perf.CrossTab(FTv, ATv, CLv, True)
            TablesLM[_area] = Perf.CrossTab(FTv, ATv, LMv, True)
                                  
        end //end if summary flag = 1 and setcount > 0
    end //end loop over summary areas
    CloseView(link_lyr)
   
    //Organize tables for writing
    Tables = null    
    
    //Summary By County
    for jj = 1 to TableGroup.length do
        TB = null
        TB.Section1 = "By County"
        TB.Name = NameGroup[jj]  + ' <span class="grey">(By County)</span>' 
        TB.Table.ColNames = Perf.Info.Counties + {"Total"}
        TB.Table.TableData = TablesCounty[jj]
        TB.Table.Formats = "*0,."
    
        Tables = Tables + {CopyArray(TB)}
    end
    
    //Version for general report, by county only and without expandable section
    Tables2 = CopyArray(Tables)
    for ii = 1 to Tables2.length do
        Tables2[ii].Section1 = null
    end
    
    //By summary area
    for ii = 1 to areas.length do
        //Tables
        for jj = 1 to TableGroup.length do
            TB = null
            TB.Section1 = areas[ii][1]
            TB.Name = NameGroup[jj]  + ' <span class="grey">('+areas[ii][1]+')</span>' 
            
            TB.Table.TableData = TableGroup[jj][ii]
            TB.Table.Formats = "*0,."
            
            Tables = Tables + {CopyArray(TB)}
        end
        
    end
    
    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables2, ) //General
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables, ) //Detailed
    
    RunMacro("G30 File Close All")
    Return(True)
    
EndMacro

// *****************************************************************************
// Input Transit Summary
Macro "RPT Transit Network Summary" (Perf)

    shared UT
    
    //Define files
    rts_file = Perf.Args.[Route System]
	tdbd_file= Perf.Args.[Highway DB]
    
    //Params
    pers = Perf.Args.TrnPeriods
    
    //!!! Hardcode, assumed transit time period lengths
    //             EA, AM, PM, MD, EV
    per_lengths = {3.5, 2.5, 5.5, 4, 8.5}
    
NextStep = "Load the Route System"
SetStatus(1, NextStep, )

	tdbd_info = GetDBInfo(tdbd_file)
    map = CreateMap("Route System", {{"Scope", tdbd_info[1]},{"Auto Project", "True"}})
    lyrs = AddRouteSystemLayer(map, "Route System", rts_file,)
    RunMacro("Set Default RS Style", lyrs, "True", "True")
    route_lyr = lyrs[1]
    stop_lyr  = lyrs[2]
	tnode_lyr = lyrs[4]
	tlink_lyr = lyrs[5]
    
NextStep = "Calculate Revenue Miles"
SetStatus(1, NextStep, )

    //Join stops to routes in order to get route lengths
    {flds, } = GetFields(stop_lyr, "All")
    agg_sets = null
    for f in flds do
        if f = "Milepost" then do
            agg_sets = agg_sets + {{f, {{"Max"}}} }
        end else do
            agg_sets = agg_sets + {{f, null}}
        end
    end
    
    Opts = {{"A"}, {"Fields", agg_sets}}
    join_vw = JoinViews("Routes+Stops", route_lyr+".Route_ID", stop_lyr+".Route_ID", Opts)
    
    flds = null
    for ii = 1 to pers.length do
        per = pers[ii]
        exp = "if "+per+"_HDWY >= 999 then 0 else ("+String(per_lengths[ii]) + " * 60 / "+per+"_HDWY) * [High Milepost]"
        flds = flds + {CreateExpression(join_vw, per+"_RevMiles", exp, )}
    end
    
NextStep = "Get Data by Route Name"
SetStatus(1, NextStep, )

    //Load data into a table
    Data = GetDataVectors(join_vw+"|", {"Route_Name"}+flds, {{"Sort Order", {{"Route_Name", "Ascending"}}}})
    
    //Totals
    dy = 0
    for ii = 2 to Data.length do
        dy = dy + nz(Data[ii])
        total_row = total_row + {VectorStatistic(Data[ii], "Sum", )}
    end
    Data = Data + {dy}
    
    total_row = total_row + {VectorStatistic(dy, "Sum", )}
    
    for ii = 1 to Data.length do //convert vectors to arrays
        Data[ii] = V2A(Data[ii])
    end

NextStep = "Get Data by Route Number"
SetStatus(1, NextStep, )

    //Aggregate
    CreateExpression(join_vw, "AggBy", 'if RT_NUMBER = null then (RT_AUTHOR + " " + RT_NAME) else (RT_AUTHOR + " " + RT_NUMBER)', )
    agg_sets = {{"RT_AUTHOR", "Dom"}, {"RT_NUMBER", "Dom"}}
    for f in flds do
        agg_sets = agg_sets + {{f, "Sum"}}
    end
    agg2_vw = AggregateTable("AggByNumber", join_vw+"|", "MEM", null, "AggBy", agg_sets, {{"Missing as zero"}})
    
    //Load data into a table
    Data2 = GetDataVectors(agg2_vw+"|", {"AggBy"}+flds, {{"Sort Order", {{"RT_AUTHOR", "Ascending"}, {"RT_NUMBER", "Ascending"}}}})
    
    //Totals
    dy = 0
    for ii = 2 to Data2.length do
        dy = dy + nz(Data2[ii])
    end
    Data2 = Data2 + {dy}
    
    for ii = 1 to Data2.length do //convert vectors to arrays
        Data2[ii] = V2A(Data2[ii])
    end
       
    CloseView(agg2_vw)
    
    
NextStep = "Get On-Off Data by Operator"
SetStatus(1, NextStep, )

    agg_sets = null
    for f in flds+SH_flds do
        agg_sets = agg_sets + {{f, "Sum"}}
    end
    agg3_vw = AggregateTable("AggByOperator", join_vw+"|", "MEM", null, "RT_AUTHOR", agg_sets, {{"Missing as zero"}})
    
    //Load data into a table
    Data3 = GetDataVectors(agg3_vw+"|", {"RT_AUTHOR"}+flds, {{"Sort Order", {{"RT_AUTHOR", "Ascending"}}}})
    
    //Totals
    dy = 0
    for ii = 2 to Data3.length do
        dy = dy + nz(Data3[ii])
    end
    Data3 = Data3 + {dy}
    
    for ii = 1 to Data3.length do //convert vectors to arrays
        Data3[ii] = V2A(Data3[ii])
    end
    
    CloseView(agg3_vw)
    
    //Close remaining views
    CloseView(join_vw)
    CloseMap(map)
    
    
NextStep = "Tranform for Table Write"
SetStatus(1, NextStep, )

    //Detailed version
    RowNames = Data[1] + {"Total"}
    TableData = TransposeArray(ExcludeArrayElements(Data, 1, 1))
    TableData = TableData + {total_row}
    
    //Aggregate version
    RowNames2 = Data2[1] + {"Total"}
    TableData2 = TransposeArray(ExcludeArrayElements(Data2, 1, 1))
    TableData2 = TableData2 + {total_row}
    
    //Operator version
    RowNames3 = Data3[1] + {"Total"}
    TableData3 = TransposeArray(ExcludeArrayElements(Data3, 1, 1))
    TableData3 = TableData3 + {total_row}
    
NextStep = "Write boarding tables"
SetStatus(1, NextStep, )
    // ==== By Operator ====
    
    TB = null
    TB.Section1 = "By Operator"
    TB.Name = "Transit Revenue Miles by Operator"
    TB.Table.TableData = TableData3
    TB.Table.RowNames = RowNames3
    TB.Table.ColNames = {"Route"}+pers+{"DY"} //col_names
    TB.Table.Formats = "*,.0" //fmts
    
    Tables = Tables + {TB}

    // ==== By Operator and Route ====
    TB = null
    TB.Section1 = "By Route"
    TB.Name = "Transit Revenue Miles by Operator and Number"
    TB.Table.TableData = TableData2
    TB.Table.RowNames = RowNames2
    TB.Table.ColNames = {"Route"}+pers+{"DY"} //col_names
    TB.Table.Formats = "*,.0" //fmts
    
    Tables = Tables + {TB}
    

    // ==== Detailed Version ====
    
    TB = null
    TB.Section1 = "By Route"
    TB.Section2 = "Additional Details"
    TB.Name = "Transit Revenue Miles by Route"
    TB.Table.TableData = TableData
    TB.Table.RowNames = RowNames
    TB.Table.ColNames = {"Route"}+pers+{"DY"} //col_names
    TB.Table.Formats = "*,.0" //fmts
    
    Tables = Tables + {TB}
    
    Perf.WriteTables(Tables)
	
	SetStatus(1, "@System0", )
    RunMacro("G30 File Close All")
    Return(True)
    
EndMacro //End of Transit Assignment Summary

Macro "RPT Socioeconomic Data" (Perf)

    shared UT

    
    //Load information
    
    areas = Perf.ActiveAreas("Zones")
    Output_dir = Perf.Args.Info.[Output Directory]    
    ABMVIZ_Directory = Output_dir + "ActivitySim\\Visualizer"

    //ABMVIZ_Directory = "C:\\Projects\\SEMCOG\\Model_Runs\\SEMCOG_ABM\\Input\\Visualizer\\data\\SEMCOG_ABM"
    Lu_County = ABMVIZ_Directory  +"\\transcad_report_LU.csv"
    HH_County = ABMVIZ_Directory + "\\transcad_report_HH.csv"

    hhsize_income = ABMVIZ_Directory + "\\transcad_report_hhsize_income.csv"
    hhsize_numchild = ABMVIZ_Directory + "\\transcad_report_hhsize_numchild.csv"
    hhsize_auto = ABMVIZ_Directory + "\\transcad_report_hhsize_auto.csv"
    hhworker_auto = ABMVIZ_Directory + "\\transcad_report_hhworker_auto.csv"
    hhworker_income = ABMVIZ_Directory + "\\transcad_report_hhworker_income.csv"
    income_auto = ABMVIZ_Directory + "\\transcad_report_income_auto.csv"
    transcad_report_Personindustry = ABMVIZ_Directory + "\\transcad_report_Personindustry.csv"

    HH_CountyView = OpenTable("HH_County","CSV",{HH_County})
    SetView(HH_CountyView)
    
    {variable, Detroit, Wayne, Oakland, Macomb, Washtenaw, Monroe, StClair, Livingston, All} = GetDataVectors(HH_CountyView+"|", {"variable","Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"},)
    
    // todo: check these purposes!
    RowNames1 = variable
    dim TableData1[RowNames1.length, 9]
    fmts1 = CopyArray(TableData1)

    for i=1 to RowNames1.length do
        for j=1 to 9 do
            fmts1[i][j] = "*,."
        end
    end
    
    TableData1[1][1] = Detroit[1]               TableData1[1][2] = Wayne[1]
    TableData1[2][1] = Detroit[2]               TableData1[2][2] = Wayne[2]
    TableData1[3][1] = Detroit[3]               TableData1[3][2] = Wayne[3]
    TableData1[4][1] = Detroit[4]               TableData1[4][2] = Wayne[4]
    TableData1[5][1] = Detroit[5]               TableData1[5][2] = Wayne[5]
    TableData1[6][1] = Detroit[6]               TableData1[6][2] = Wayne[6]
    TableData1[7][1] = Detroit[7]               TableData1[7][2] = Wayne[7]
    TableData1[8][1] = Detroit[8]               TableData1[8][2] = Wayne[8]
    TableData1[9][1] = Detroit[9]               TableData1[9][2] = Wayne[9]
    TableData1[10][1] = Detroit[10]               TableData1[10][2] = Wayne[10]
    TableData1[11][1] = Detroit[11]               TableData1[11][2] = Wayne[11]
    TableData1[12][1] = Detroit[12]               TableData1[12][2] = Wayne[12]
    //
    TableData1[1][3] = Oakland[1]               TableData1[1][4] = Macomb[1]
    TableData1[2][3] = Oakland[2]               TableData1[2][4] = Macomb[2]
    TableData1[3][3] = Oakland[3]               TableData1[3][4] = Macomb[3]
    TableData1[4][3] = Oakland[4]               TableData1[4][4] = Macomb[4]
    TableData1[5][3] = Oakland[5]               TableData1[5][4] = Macomb[5]
    TableData1[6][3] = Oakland[6]               TableData1[6][4] = Macomb[6]
    TableData1[7][3] = Oakland[7]               TableData1[7][4] = Macomb[7]
    TableData1[8][3] = Oakland[8]               TableData1[8][4] = Macomb[8]
    TableData1[9][3] = Oakland[9]               TableData1[9][4] = Macomb[9]
    TableData1[10][3] = Oakland[10]               TableData1[10][4] = Macomb[10]
    TableData1[11][3] = Oakland[11]               TableData1[11][4] = Macomb[11]
    TableData1[12][3] = Oakland[12]               TableData1[12][4] = Macomb[12]
    //
    TableData1[1][5] = Washtenaw[1]               TableData1[1][6] = Monroe[1]
    TableData1[2][5] = Washtenaw[2]               TableData1[2][6] = Monroe[2]
    TableData1[3][5] = Washtenaw[3]               TableData1[3][6] = Monroe[3]
    TableData1[4][5] = Washtenaw[4]               TableData1[4][6] = Monroe[4]
    TableData1[5][5] = Washtenaw[5]               TableData1[5][6] = Monroe[5]
    TableData1[6][5] = Washtenaw[6]               TableData1[6][6] = Monroe[6]
    TableData1[7][5] = Washtenaw[7]               TableData1[7][6] = Monroe[7]
    TableData1[8][5] = Washtenaw[8]               TableData1[8][6] = Monroe[8]
    TableData1[9][5] = Washtenaw[9]               TableData1[9][6] = Monroe[9]
    TableData1[10][5] = Washtenaw[10]               TableData1[10][6] = Monroe[10]
    TableData1[11][5] = Washtenaw[11]               TableData1[11][6] = Monroe[11]
    TableData1[12][5] = Washtenaw[12]               TableData1[12][6] = Monroe[12]
    //
    TableData1[1][7] = StClair[1]               TableData1[1][8] = Livingston[1]
    TableData1[2][7] = StClair[2]               TableData1[2][8] = Livingston[2]
    TableData1[3][7] = StClair[3]               TableData1[3][8] = Livingston[3]
    TableData1[4][7] = StClair[4]               TableData1[4][8] = Livingston[4]
    TableData1[5][7] = StClair[5]               TableData1[5][8] = Livingston[5]
    TableData1[6][7] = StClair[6]               TableData1[6][8] = Livingston[6]
    TableData1[7][7] = StClair[7]               TableData1[7][8] = Livingston[7]
    TableData1[8][7] = StClair[8]               TableData1[8][8] = Livingston[8]
    TableData1[9][7] = StClair[9]               TableData1[9][8] = Livingston[9]
    TableData1[10][7] = StClair[10]               TableData1[10][8] = Livingston[10]
    TableData1[11][7] = StClair[11]               TableData1[11][8] = Livingston[11]
    TableData1[12][7] = StClair[12]               TableData1[12][8] = Livingston[12]

    TableData1[1][9] = All[1]               
    TableData1[2][9] = All[2]              
    TableData1[3][9] = All[3]               
    TableData1[4][9] = All[4]               
    TableData1[5][9] = All[5]           
    TableData1[6][9] = All[6]               
    TableData1[7][9] = All[7]             
    TableData1[8][9] = All[8]           
    TableData1[9][9] = All[9]              
    TableData1[10][9] = All[10]              
    TableData1[11][9] = All[11]            
    TableData1[12][9] = All[12]

    CloseView(HH_CountyView)
    ////

    LU_CountyView = OpenTable("LU_County","CSV",{Lu_County})
    SetView(LU_CountyView)
    
    {variable, Detroit, Wayne, Oakland, Macomb, Washtenaw, Monroe, StClair, Livingston, All} = GetDataVectors(LU_CountyView+"|", {"variable","Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"},)
    
    RowNames2 = variable
    dim TableData2[RowNames2.length, 9]
    fmts2 = CopyArray(TableData2)

    for i=1 to RowNames2.length do
        for j=1 to 9 do
            fmts2[i][j] = "*,."
        end
    end
    for i=1 to RowNames2.length do
        TableData2[i][1] = Detroit[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][2] = Wayne[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][3] = Oakland[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][4] = Macomb[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][5] = Washtenaw[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][6] = Monroe[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][7] = StClair[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][8] = Livingston[i]
    end
        for i=1 to RowNames2.length do
        TableData2[i][9] = All[i]
    end

    CloseView(LU_CountyView)
    
    hhsize_incomeView = OpenTable("hhsize_income","CSV",{hhsize_income})
    
    {variable, one, two, three, four, All} = GetDataVectors(hhsize_incomeView+"|", {"hhsize_recode","one","two","three","four","All"},)

    RowNames3 = variable
    dim TableData3[RowNames3.length, 5]
    fmts3 = CopyArray(TableData3)

    for i=1 to RowNames3.length do
        for j=1 to 5 do
            fmts3[i][j] = "*,."
        end
    end
    for i=1 to RowNames3.length do
        TableData3[i][1] = one[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][2] = two[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][3] = three[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][4] = four[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][5] = All[i]
    end

    hhsize_numchildView = OpenTable("hhsize_numchild","CSV",{hhsize_numchild})
    
    {variable, one, two, three, four, All} = GetDataVectors(hhsize_numchildView+"|", {"hhsize_recode","zero","one","two","three","All"},)

    RowNames4 = variable
    dim TableData4[RowNames4.length, 5]
    fmts4 = CopyArray(TableData4)

    for i=1 to RowNames4.length do
        for j=1 to 5 do
            fmts4[i][j] = "*,."
        end
    end
    for i=1 to RowNames4.length do
        TableData4[i][1] = one[i]
    end
    for i=1 to RowNames4.length do
        TableData4[i][2] = two[i]
    end
    for i=1 to RowNames4.length do
        TableData4[i][3] = three[i]
    end
    for i=1 to RowNames4.length do
        TableData4[i][4] = four[i]
    end
    for i=1 to RowNames4.length do
        TableData4[i][5] = All[i]
    end
    //
    hhsize_autoView = OpenTable("hhsize_auto","CSV",{hhsize_auto})
    
    {variable, zero, one, two, three, four, All} = GetDataVectors(hhsize_autoView+"|", {"hhsize_recode","zero","one","two","three","four","All"},)

    RowNames5 = variable
    dim TableData5[RowNames5.length, 6]
    fmts5 = CopyArray(TableData5)

    for i=1 to RowNames5.length do
        for j=1 to 6 do
            fmts5[i][j] = "*,."
        end
    end
    for i=1 to RowNames5.length do
        TableData5[i][1] = zero[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][2] = one[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][3] = two[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][4] = three[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][5] = four[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][6] = All[i]
    end
    //
    hhworker_autoView = OpenTable("hhworker_auto","CSV",{hhworker_auto})
    
    {variable, zero, one, two, three, four, All} = GetDataVectors(hhworker_autoView+"|", {"num_workers_recode","zero","one","two","three","four","All"},)

    RowNames6 = variable
    dim TableData6[RowNames6.length, 6]
    fmts6 = CopyArray(TableData6)

    for i=1 to RowNames6.length do
        for j=1 to 6 do
            fmts6[i][j] = "*,."
        end
    end
    for i=1 to RowNames6.length do
        TableData6[i][1] = zero[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][2] = one[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][3] = two[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][4] = three[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][5] = four[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][6] = All[i]
    end
    //
    hhworker_incomeView = OpenTable("hhworker_income","CSV",{hhworker_income})
    
    {variable, one, two, three, four, All} = GetDataVectors(hhworker_incomeView+"|", {"num_workers_recode","one","two","three","four","All"},)

    RowNames7 = variable
    dim TableData7[RowNames7.length, 5]
    fmts7 = CopyArray(TableData7)

    for i=1 to RowNames7.length do
        for j=1 to 5 do
            fmts7[i][j] = "*,."
        end
    end
    for i=1 to RowNames7.length do
        TableData7[i][1] = one[i]
    end
    for i=1 to RowNames7.length do
        TableData7[i][2] = two[i]
    end
    for i=1 to RowNames7.length do
        TableData7[i][3] = three[i]
    end
    for i=1 to RowNames7.length do
        TableData7[i][4] = four[i]
    end
    for i=1 to RowNames7.length do
        TableData7[i][5] = All[i]
    end
    //
    income_autoView = OpenTable("income_auto","CSV",{income_auto})
    
    {variable, zero, one, two, three, four, All} = GetDataVectors(income_autoView+"|", {"income_segment","zero","one","two","three","four","All"},)

    RowNames8 = variable
    dim TableData8[RowNames8.length, 6]
    fmts8 = CopyArray(TableData8)

    for i=1 to RowNames8.length do
        for j=1 to 6 do
            fmts8[i][j] = "*,."
        end
    end
    for i=1 to RowNames8.length do
        TableData8[i][1] = zero[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][2] = one[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][3] = two[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][4] = three[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][5] = four[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][6] = All[i]
    end

    transcad_report_PersonindustryView = OpenTable("transcad_report_Personindustry","CSV",{transcad_report_Personindustry})
    SetView(transcad_report_PersonindustryView)
    
    {variable, Detroit, Wayne, Oakland, Macomb, Washtenaw, Monroe, StClair, Livingston, All} = GetDataVectors(transcad_report_PersonindustryView+"|", {"industry_name","Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"},)
    
    RowNames9 = variable
    dim TableData9[RowNames9.length, 9]
    fmts9 = CopyArray(TableData9)

    for i=1 to RowNames9.length do
        for j=1 to 9 do
            fmts9[i][j] = "*,."
        end
    end
    for i=1 to RowNames9.length do
        TableData9[i][1] = Detroit[i]
    end
    for i=1 to RowNames9.length do
        TableData9[i][2] = Wayne[i]
    end
    for i=1 to RowNames9.length do
        TableData9[i][3] = Oakland[i]
    end
    for i=1 to RowNames9.length do
        TableData9[i][4] = Macomb[i]
    end
    for i=1 to RowNames9.length do
        TableData9[i][5] = Washtenaw[i]
    end
    for i=1 to RowNames9.length do
        TableData9[i][6] = Monroe[i]
    end
    for i=1 to RowNames9.length do
        TableData9[i][7] = StClair[i]
    end
    for i=1 to RowNames9.length do
        TableData9[i][8] = Livingston[i]
    end
        for i=1 to RowNames9.length do
        TableData9[i][9] = All[i]
    end

    CloseView(transcad_report_PersonindustryView)

    ///
    TB = null
    TB.Name = "Household Data Summary by County"
    TB.Section1 = "Totals by County"
    TB.Table.TableData = TableData1
    TB.Table.RowNames = {"Total Households","Total Population","Low-income Households","Full-time Workers","Part-time Workers","College Students","Driving-age Students","Non-Driving-age Students","Children (Age 17 and under)","Seniors (65+)","Zero-Auto Households","Auto-deficient Households"}
    TB.Table.ColNames = {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "St. Clair", "Livingston", "All"}
    TB.Table.Formats = fmts1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Landuse Data Summary by County"
    TB.Section1 = "Totals by County"
    TB.Table.TableData = TableData2
    TB.Table.RowNames = {'Grade K-8 Enrollment', 'Grade 9-12 Enrollment',
       'University Enrollment', 'Natural Resources & Mining', 'Construction', 'Manufacturing', 
       'Wholesale Trade', 'Retail Trade', 'Transportation & Warehousing', 'Utilities', 'Information', 'Financial Activities', 
       'Professional, Scientific, & Technical Services', 'Management of Companies & Enterprises', 'Administrative, Support, & Waste Services', 
       'Educational Services', 'Health Care & Social Assistance', 'Arts, Entertainment, & Recreation', 'Accommodation & Food Services', 'Other Services', 'Public Administration',
       'Total Employment'}
    TB.Table.ColNames = {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "St. Clair", "Livingston", "All"}
    TB.Table.Formats = fmts2
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Synthetic Population Data Summary by County"
    TB.Section1 = "Totals by County"
    TB.Table.TableData = TableData9
    TB.Table.RowNames = {'Natural Resources & Mining', 'Construction', 'Manufacturing', 
       'Wholesale Trade', 'Retail Trade', 'Transportation & Warehousing', 'Utilities', 'Information', 'Financial Activities', 
       'Professional, Scientific, & Technical Services', 'Management of Companies & Enterprises', 'Administrative, Support, & Waste Services', 
       'Educational Services', 'Health Care & Social Assistance', 'Arts, Entertainment, & Recreation', 'Accommodation & Food Services', 'Other Services', 'Public Administration', 'Total'}

    TB.Table.ColNames = {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "St. Clair", "Livingston", "All"}
    TB.Table.Formats = fmts9
    TB.Table.Class = "dataframe no-last-any"
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Household Size by HH Income (Entire Model)"
    TB.Section1 = "Households Totals by Segments"
    TB.Table.TableData = TableData3
    TB.Table.RowNames = {'1 Person', '2 Person', '3 Person', '4 Person', '5+ Person', 'Total'}
    TB.Table.ColNames = {'Low Income', 'Low-Med Income', 'Med-High Income', 'High Income', 'Total'}
    TB.Table.Formats = fmts3
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Household Size by No. of Children (Entire Model)"
    TB.Section1 = "Households Totals by Segments"
    TB.Table.TableData = TableData4
    TB.Table.RowNames = {'1 Person', '2 Person', '3 Person', '4 Person', '5+ Person', 'Total'}
    TB.Table.ColNames = {'0 child', '1 child', '2 children', '3+ children', 'Total'}
    TB.Table.Formats = fmts4
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Household Size by No. of Autos (Entire Model)"
    TB.Section1 = "Households Totals by Segments"
    TB.Table.TableData = TableData5
    TB.Table.RowNames = {'1 Person', '2 Person', '3 Person', '4 Person', '5+ Person', 'Total'}
    TB.Table.ColNames = {'0 Auto', '1 Auto', '2 Autos', '3 Autos', '4+ Autos', 'Total'}
    TB.Table.Formats = fmts5
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Household Workers by No. of Autos (Entire Model)"
    TB.Section1 = "Households Totals by Segments"
    TB.Table.TableData = TableData6
    TB.Table.RowNames = {'0 Worker', '1 Worker', '2 Workers', '3+ Workers', 'Total'}
    TB.Table.ColNames = {'0 Auto', '1 Auto', '2 Autos', '3 Autos', '4+ Autos', 'Total'}
    TB.Table.Formats = fmts6
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Household Workers by Income (Entire Model)"
    TB.Section1 = "Households Totals by Segments"
    TB.Table.TableData = TableData7
    TB.Table.RowNames = {'0 Worker', '1 Worker', '2 Workers', '3+ Workers', 'Total'}
    TB.Table.ColNames = {'Low Income', 'Low-Med Income', 'Med-High Income', 'High Income', 'Total'}
    TB.Table.Formats = fmts7
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Household Income by No. of Autos (Entire Model)"
    TB.Section1 = "Households Totals by Segments"
    TB.Table.TableData = TableData8
    TB.Table.RowNames = {'Low Income', 'Low-Med Income', 'Med-High Income', 'High Income', 'Total'}
    TB.Table.ColNames = {'0 Auto', '1 Auto', '2 Autos', '3 Autos', '4+ Autos', 'Total'}
    TB.Table.Formats = fmts8
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables, ) //General

    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)

    Return(True)
EndMacro //end of sociodata report

Macro "GetCrossClassLabel" (ii, lbl, max)

    if TypeOf(lbl) = 'string' then do
        if ii < max then Return(String(ii) + " " + lbl)
        else Return(String(ii) + "+ " + lbl)
    end else if TypeOf(lbl) = 'array' and ii <= lbl.length then do
        Return(lbl[ii])
    end else do
        Return ("Category " + String(ii))
    end

EndMacro

// *************************************************************************************************
// &&& Trip Generation 
// *************************************************************************************************

Macro "RPT Trip Generation" (Perf)

	//Set up utilities
	shared UT

    //define files
    pa_files = {Perf.Args.[PATable], Perf.Args.[Unbal PATable]} //bal/unbal
    pa_id = {"ID", "ID"} //bal/unbal
    pa_fld = {"p", "a"}
    sed_file = Perf.Args.[TAZ Data Table]
    
    //define params
    purp_names = Perf.Args.Purps
    purp_seg = Perf.Args.PurpSeg
    
    //Add truck trips to purpose definitions
    purp_names = purp_names + {"LightTruck", "MedTruck", "HeavTruck"}
    purp_seg = purp_seg + {0, 0, 0}
    
    //Replace HBU with HBUniv
    purp_names[ArrayPosition(purp_names, {"HBU"}, )] = "HBUniv"
    
    //Segmentation settings
    // - Trips are added up over combinations of INC and VEH
	INC = {"Inc", "quartile", 1, 4} 
	VEH = {"V", "VehSuf", 1, 3}
    inc_names = {"Low", "Med-Low", "Med-High", "High"}

    areas = Perf.ActiveAreas("Zones", True) //Always summarize all areas
    
    //Open tables and files
    sed_vw = OpenTable("SED", "FFB", {sed_file})
    
    //Identify airport trips
    SetView(sed_vw)
    SelectByQuery("AZ", "Several", "Select * Where AirportADT > 0", )
    AirportZones = V2A(GetDataVector(sed_vw+"|AZ", "ID", ))
    air_qry = "Select * Where ID = " + JoinStrings(AirportZones, " or ID = ")
    DeleteSet("AZ")
    
    //Identify external zones
    SelectByQuery("EXT", "Several", "Select * Where External > 0", )
    ExternalZones = V2A(GetDataVector(sed_vw+"|EXT", "ID", ))
    ext_qry = "Select * Where ID = " + JoinStrings(ExternalZones, " or ID = ")
    DeleteSet("EXT")
    
    Tables = null
    Tables2 = null

    
    //Summarize by area, bal/unbal
    for _area = 1 to areas.length do
        {areaName, areaQRY, areaField, areaValue} = areas[_area]
        for bal = 1 to 2 do
        
            //Initialize External and Airport Trip totals
            Pint_tot = 0
            Aint_tot = 0
            Pext_tot = 0
            Aext_tot = 0
            Pair_tot = 0
            Aair_tot = 0
        
            //Dimension TableData
            dim Data[purp_names.length, 7] //cols: (1)prod, (2)attr, (3)p/HH, (4)p/POP, (5)a/emp, (6)% P, (7)% A
            dim Data2[purp_names.length, 6] //cols: (1) internal P (2) internal A (3) External P (4) External A (5) Airport P (6) Airport A
            
            //Load bal/unbal data
            pa_vw = OpenTable("PA", "FFB", {pa_files[bal],})
            join_vw = JoinViews("Join", pa_vw+"."+pa_id[bal], sed_vw+".ID", )
            
            Flds = {sed_vw+".Households", "HHPop", "EmpPrinc", "External", "AirportADT"}
            if areaField != null then Flds = Flds + {areaField} //subarea selection field
            for _purp = 1 to purp_names.length do
                purp = purp_names[_purp]
                if purp_seg[_purp] then do
                    for _inc = INC[3] to INC[4] do
                        inc = String(_inc)
                        for _veh = VEH[3] to VEH[4] do
                            veh = String(_veh)
                            Flds = Flds + {purp+"_Inc"+inc+"V"+veh+"p", purp+"_Inc"+inc+"V"+veh+"a"}
                        end //_veh
                    end //_inc
                end //segmented
                else do
                    Flds = Flds + {purp+"p", purp+"a"}
                end
            end
            DATA = GetDataVectors(join_vw+"|", Flds, {{"Return Options Array", "True"}})
            CloseView(join_vw)
            CloseView(pa_vw)
            
            
            
            p_tot = 0
            a_tot = 0
            
            //SED Basics
            hh = DATA.(sed_vw+".Households")
            pop = DATA.HHPop
            emp = DATA.EmpPrinc
            if areaField != null then do //filter subareas
                hh = if DATA.(areaField) = areaValue then hh else 0
                pop = if DATA.(areaField) = areaValue then pop else 0
                emp = if DATA.(areaField) = areaValue then emp else 0
            end
            
            hh = VectorStatistic(hh, "Sum", )
            pop = VectorStatistic(pop, "Sum", )
            emp = VectorStatistic(emp, "Sum", )
            
            //Populate table for each purpose
            for _purp = 1 to purp_names.length do
                purp = purp_names[_purp]
                
                // **** Get P and A vectors ****
                //Income segmentation?
                if purp_seg[_purp] then do
                    P = 0
                    A = 0
                    for _inc = INC[3] to INC[4] do
                        inc = String(_inc)
                        for _veh = VEH[3] to VEH[4] do
                            veh = String(_veh)
                            
                            fld = purp+"_Inc"+inc+"V"+veh
                            
                            P = P + nz(DATA.(fld+"p"))
                            A = A + nz(DATA.(fld+"a"))
                        end //_veh
                    end //_inc
                end //segmented
                else do
                    P = nz(DATA.(purp+"p"))
                    A = nz(DATA.(purp+"a"))
                end
                
                // **** Filter subarea ****
                if areaField != null then do //filter subareas
                    P = if DATA.(areaField) = areaValue then P else 0
                    A = if DATA.(areaField) = areaValue then A else 0
                end
                P_sum = VectorStatistic(P, "Sum", )
                A_sum = VectorStatistic(A, "Sum", )
                
                Data[_purp][1] = P_sum
                Data[_purp][2] = A_sum
                Data[_purp][3] = P_sum / hh
                Data[_purp][4] = P_sum / pop
                Data[_purp][5] = A_sum / emp
                
                //accumulate totals
                p_tot = p_tot + P_sum
                a_tot = a_tot + A_sum
                
                // **** Filter external and airport ****
                Pint = VectorStatistic(if nz(DATA.External) = 0 then P else 0, "Sum", )
                Aint = VectorStatistic(if nz(DATA.External) = 0 then A else 0, "Sum", )
                Pext = VectorStatistic(if DATA.External > 0 then P else 0, "Sum", )
                Aext = VectorStatistic(if DATA.External > 0 then A else 0, "Sum", )
                Pair = VectorStatistic(if DATA.AirportADT > 0 then P else 0, "Sum", )
                Aair = VectorStatistic(if DATA.AirportADT > 0 then A else 0, "Sum", )
                
                //Create data table
                Data2[_purp][1] = Pint
                Data2[_purp][2] = Aint
                Data2[_purp][3] = Pext
                Data2[_purp][4] = Aext
                Data2[_purp][5] = Pair
                Data2[_purp][6] = Aair

                //Accumulate totals
                Pint_tot = nz(Pint_tot) + nz(Pint)
                Aint_tot = nz(Aint_tot) + nz(Aint)
                Pext_tot = nz(Pext_tot) + nz(Pext)
                Aext_tot = nz(Aext_tot) + nz(Aext)
                Pair_tot = nz(Pair_tot) + nz(Pair)
                Aair_tot = nz(Aair_tot) + nz(Aair)
                
            end //_purp
            
            //Add totals row
            Data = Data + {{p_tot, a_tot, p_tot / hh, p_tot / pop, a_tot/emp, , }}
            Data2 = Data2 + {{Pint_tot, Aint_tot, Pext_tot, Aext_tot, Pair_tot, Aair_tot}}
            
            //Get percentages of totals, 
            for _purp = 1 to Data.length do
                Data[_purp][6] = Data[_purp][1] / p_tot
                Data[_purp][7] = Data[_purp][2] / a_tot
            end
            
            //Create cell format overrides
            for _purp = 1 to Data.length do
                cell_fmt = cell_fmt + {{, , "*0.00", "*0.00", "*0.00", "*0.0%", "*0.0%"}}
            end
            
            //Save table for writing
            TB = null
            TB.Name = if bal = 1 then "Balanced Trips" else "Unbalanced Trips"
            TB.Name = TB.Name + ' <span class="grey">('+areaName+')</span>'
            TB.Section1 = areaName
            if bal > 1 then TB.Section2 = "Additional Details"
            TB.Table.TableData = CopyArray(Data)
            TB.Table.RowNames = purp_names + {"All Trips"}
            TB.Table.ColNames = {"Purpose", "Productions", "Attractions", "Productions/HH", "Productions/Pop", "Attractions/Emp", "% of Productions", "% of Attractions"}
            TB.Table.Formats = cell_fmt
            TB.Table.Class = "dataframe no-last-col"
            
            Tables = Tables + {CopyArray(TB)}
            
            //Add a chart
            txData = TransposeArray(Data)
            chP = Subarray(txData[1], 1, txData[1].length-1)
            chA = Subarray(txData[2], 1, txData[2].length-1)
            
            CH = null
            basic_name = if bal = 1 then "Balanced Trips Visualization" else "Unbalanced Trips Visualization"
            CH.Name = basic_name + ' <span class="grey">('+areaName+')</span>'
            CH.Section1 = areaName
            if bal > 1 then CH.Section2 = "Additional Details"
            CH.Chart.CanvasID = 'chart_'+Substitute(basic_name+"_"+areaName, " ", "_",)
            CH.Chart.Type = 'bar'
            CH.Chart.Labels = purp_names
            CH.Chart.Data = {chP, chA}
            CH.Chart.Names = {"Productions", "Attractions"}
            
            Tables = Tables + {CopyArray(CH)}
            
            //General Report
            if bal = 1 and _area = 1 then do
                TB.Section1 = null
                CH.Section1 = null
                Tables2 = Tables2 + {CopyArray(TB)}
                Tables2 = Tables2 + {CopyArray(CH)}
            end
            
            //Add external and airport table
            TB = null
            TB.Name = if bal = 1 then "Balanced External and Airport Trips" else "Unbalanced External and Airport Trips"
            TB.Name = TB.Name + ' <span class="grey">('+areaName+')</span>'
            TB.Section1 = areaName
            if bal > 1 then TB.Section2 = "Additional Details"
            TB.Table.TableData = CopyArray(Data2)
            TB.Table.RowNames = purp_names + {"All Trips"}
            TB.Table.ColNames = {"Internal P", "Internal A", "External P", "External A", "Airport P", " Airport A"}
            TB.Table.Formats = "*,."
            TB.Table.Class = "dataframe no-last-col"
            
            Tables = Tables + {CopyArray(TB)}
            
        end //bal/unbal
    end //area
    CloseView(sed_vw)
    
    //Write tables to file
    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)
    
    Return(True)
EndMacro


Macro "RPT Trip Distribution" (Perf)

    shared UT
    
	//Params
    pkop_pers  = Perf.Args.PkOpPeriods
    orig_purps = Perf.Args.Purps
    purp_seg = Perf.Args.PurpSeg
    Verbose = False
    
    //Add truck trips to purpose definitions
    //Warning: Specific coding to summarize these for daily only.
    purps = orig_purps + {"LightTruck", "MedTruck", "HeavyTruck"}
    purp_seg = purp_seg + {0, 0, 0}

    //Segmentation settings
    // - Trips are added up over combinations of INC and VEH
    inc_segs = Perf.Args.IncSegs
    veh_segs = Perf.Args.VehSegs
	
	skm_files = {Perf.Args.AMHwySkims, Perf.Args.MDHwySkims}
    pa_file = Perf.Args.[DC Summary]
    patrk_file = Perf.Args.Grav_Combined
    
    //Matrix indices matter - specified here
    skm_idx = {"ZoneID", "ZoneID"} //row/col index
    trp_idx = {,} //row/col index (null to use default/only index)
    
    //Format strings for data columns
    fmts = {,,,"*0.0%", "*0.0000", "*0.0000", "*0.0", "*0.0", "*0.0"}
    Tables = null
    
    Dim Data[2] //for PK and OP, used to sum into daily at the end
    
    //to accumulate daily intermediate values
    dim len_sumDY[purps.length]
    dim time_sumDY[purps.length]
    dim time_tt_sumDY[purps.length]
    
    //Open trip distribution results in memory
    pa_mat = UT.OpenMatrixMem(pa_file)
    patrk_mat = UT.OpenMatrixMem(patrk_file)
    
    //Add empty cores for skim data
    AddMatrixCore(pa_mat, "Miles")
    AddMatrixCore(pa_mat, "Trav_Time")
    AddMatrixCore(pa_mat, "SP_and_Terminal")
    AddMatrixCore(pa_mat, "SCRATCH")
    
    pa_curs1 = CreateMatrixCurrencies(pa_mat,trp_idx[1], trp_idx[2], )
    patrk_curs = CreateMatrixCurrencies(patrk_mat,trp_idx[1], trp_idx[2], )
    
    //Combine the currency opts arrays from DC and gravity
    pa_curs = pa_curs1 + patrk_curs
    
    for _per = 1 to pkop_pers.length do
        per = pkop_pers[_per]
        
        skm_mat = OpenMatrix(skm_files[_per], )
        skm_curs = CreateMatrixCurrencies(skm_mat, skm_idx[1], skm_idx[2], )
    
        //Add skim data to MEM matrix
        pa_curs.Miles := skm_curs.Miles
        pa_curs.Trav_Time := skm_curs.Trav_Time
        pa_curs.SP_and_Terminal := skm_curs.SP_and_Terminal
        
        //Done with segmented matrix and skim, so close
        skm_mat = null
        skm_curs = null
        
        //Begin data collection
        dim last_line[9] //total line for all trips
        len_sum = 0
        len_sum_pss = 0
        
        time_sum = 0
        time_sum_pss = 0
        
        time_tt_sum = 0
        time_tt_sum_pss = 0
        
        for _purp = 1 to purps.length do
            purp = purps[_purp]
            purp_per = per + "_" + purp
            dim line[9]
            //(1)trips (2)intra (3)inter (4)%inter (5)miles (6)min (7)mph (8) min(term) (9)mph(term)
            
            //For trucks, matrices are not by time period
            if Upper(Right(purp, 5)) = "TRUCK" then do
                if _per > 1 then do
                    Data[_per] = Data[_per] + {CopyArray(line)}  //add blank line to data table
                    continue //Skip except first period, since trucks are really daily
                end 
                purp_per = purp
            end
        
            //Total and intrazonal trips
            line[1] = zn(VectorStatistic(GetMatrixVector(pa_curs.(purp_per), {{"Marginal", "Row Sum"}}), "Sum", ), )
            line[2] = zn(VectorStatistic(GetMatrixVector(pa_curs.(purp_per), {{"Diagonal", "Column"}}), "Sum", ), )
            line[3] = zn(line[1] - line[2], )
            line[4] = zn(line[2] / line[1], )
            
            //Time and speed
        
            //Avg Length (Miles)
            pa_curs.SCRATCH := pa_curs.Miles * pa_curs.(purp_per)
            V = VectorStatistic(GetMatrixVector(pa_curs.SCRATCH, {{"Marginal", "Row Sum"}}), "Sum", )
            line[5] = zn(V / line[1], )
            len_sum = len_sum + V
            if _purp <= orig_purps.length then do
                len_sum_pss = len_sum_pss + V
            end
            len_sumDY[_purp] = nz(len_sumDY[_purp]) + V
            
            //Avg time (no terminal time)
            pa_curs.SCRATCH := pa_curs.Trav_Time * pa_curs.(purp_per)
            V = VectorStatistic(GetMatrixVector(pa_curs.SCRATCH, {{"Marginal", "Row Sum"}}), "Sum", )
            line[6] = zn(V / line[1], )
            time_sum = time_sum + V
            if _purp <= orig_purps.length then do
                time_sum_pss = time_sum_pss + V
            end
            time_sumDY[_purp] = nz(time_sumDY[_purp]) + V
            
            //Avg Speed (no term)
            line[7] = zn(line[5] / line[6] * 60, )
            
            //Avg time (with termainl time)
            pa_curs.SCRATCH := pa_curs.SP_and_Terminal * pa_curs.(purp_per)
            V = VectorStatistic(GetMatrixVector(pa_curs.SCRATCH, {{"Marginal", "Row Sum"}}), "Sum", )
            line[8] = zn(V / line[1], )
            time_tt_sum = time_tt_sum + V
            if _purp <= orig_purps.length then do
                time_tt_sum_pss = time_tt_sum_pss + V
            end
            time_tt_sumDY[_purp] = nz(time_tt_sumDY[_purp]) + V
            
            //Avg Speed (no term)
            line[9] = zn(line[5] / line[8] * 60, )
            
            
            //Add line to table, address formatting
            Data[_per] = Data[_per] + {CopyArray(line)}
            
            //Sum totals
            last_line[1] = nz(last_line[1]) + nz(line[1])
            last_line[2] = nz(last_line[2]) + nz(line[2])
            last_line[3] = nz(last_line[3]) + nz(line[3])
            last_line[4] = nz(last_line[2]) / last_line[1]
            
        end
        
        //Calculate total time and speed
        last_line[5] = len_sum / last_line[1]
        last_line[6] = time_sum / last_line[1]
        last_line[7] = last_line[5] / last_line[6] * 60
        last_line[8] = time_tt_sum / last_line[1]
        last_line[9] = last_line[5] / last_line[8] * 60
        
        Data[_per] = Data[_per] + {CopyArray(last_line)}
        
        
        //Remove truck lines from peak and off-peak tables before writing
        PerData = Subarray(Data[_per], 1, orig_purps.length)
        
        //Add total for peak and off-peak tables
        dim line[PerData[1].length]
        for ii = 1 to PerData.length do
        
            //Sum trips, intrazonal, interzonal
            line[1] = nz(line[1]) + nz(PerData[ii][1])
            line[2] = nz(line[2]) + nz(PerData[ii][2])
            line[3] = nz(line[3]) + nz(PerData[ii][3])
            
        end
        
         //% intrazonal
        line[4] = line[2] / line[1]
            
        //Calculate total time and speed
        line[5] = len_sum_pss / line[1]
        line[6] = time_sum_pss / line[1]
        line[7] = line[5] / line[6] * 60
        line[8] = time_tt_sum_pss / line[1]
        line[9] = line[5] / line[8] * 60
        
        PerData = PerData + {CopyArray(line)}
        
        //Formats required for each line
        Formats = null
        for ii = 1 to PerData.length do
            Formats = Formats + {fmts}
        end
        
        TB = null
        TB.Section1 = pkop_pers[_per]
        TB.Name = "Trip Distribution Summary"
        TB.Footnote = "<p>* Differences from trip generation are due to additional trip-ends introduced by the external model. <br/>** Includes terminal time.</p>"
        TB.Table.TableData = CopyArray(PerData)
        TB.Table.Formats = CopyArray(Formats)
        TB.Table.RowNames = orig_purps + {"All Trips"}
        TB.Table.ColNames = {"Purpose", "Trips*", "Intrazonal", "Interzonal", "% Intrazonal", "Avg Length (miles)", "Avg Time (min)", "Avg Speed", "Avg Time (min)**", "Avg Speed**"}
        TB.Table.Class = "dataframe no-last-col"
        
        Tables = Tables + {CopyArray(TB)}
        
    end //_per
    
    //Close (and delete) memory matrices
    pa_mat = null
    pa_curs = null
    
    //totals over all purps
    len_sumDY = len_sumDY + {Sum(len_sumDY)}
    time_sumDY = time_sumDY + {Sum(time_sumDY)}
    time_tt_sumDY = time_tt_sumDY + {Sum(time_tt_sumDY)}
    
    //Add daily table by summing PK and OP
    DataDY = null
    for _purp = 1 to Data[1].length do
        dim line[9]
        for ii = 1 to 3 do
            line[ii] = nz(Data[1][_purp][ii]) + nz(Data[2][_purp][ii]) //OP does not have truck lines
        end
        line[4] = line[2] / line[1]
        
        //Speeds and times
        
        line[5] = len_sumDY[_purp] / line[1]
        line[6] = time_sumDY[_purp] / line[1]
        line[7] = line[5] / line[6] * 60
        line[8] = time_tt_sumDY[_purp] / line[1]
        line[9] = line[5] / line[8] * 60
        
        DataDY = DataDY + {CopyArray(line)}
        
    end
    
    //Formats required for each line
    Formats = null
    for ii = 1 to DataDY.length do
        Formats = Formats + {fmts}
    end
    
    TB = null
    TB.Section1 = "Daily"
    TB.Name = "Trip Distribution Summary"
    TB.Footnote = "<p>* Differences from trip generation are due to additional trip-ends introduced by the external model. <br/>** Includes terminal time.</p>"
    TB.Table.TableData = CopyArray(DataDY)
    TB.Table.Formats = CopyArray(Formats) //remains from pk / op
    TB.Table.RowNames = purps + {"All Trips"}
    TB.Table.ColNames = {"Purpose", "Trips*", "Intrazonal", "Interzonal", "% Intrazonal", "Avg Length (miles)", "Avg Time (min)", "Avg Speed", "Avg Time (min)**", "Avg Speed**"}
    TB.Table.Class = "dataframe no-last-col"
    
    Tables = {CopyArray(TB)} + Tables
    
    //General Report
    TB.Section1 = null
    Tables2 = {CopyArray(TB)}

    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)
    
    Return(True)
EndMacro

Macro "RPT Trip Length Frequencies" (Perf)

    shared UT
    
	//Params
    max_plot_time = 60 //Maximum time to include in plots
    pkop_pers  = Perf.Args.PkOpPeriods
    purps = Perf.Args.Purps
    purp_seg = Perf.Args.PurpSeg
    Verbose = True //!!! Must use verbose until TLFD is updated to use memory matrix, or summing is done in Trip Dist instead

    //Segmentation settings
    // - Trips are added up over combinations of INC and VEH
    inc_segs = Perf.Args.IncSegs
    veh_segs = Perf.Args.VehSegs
	
	skm_files = {Perf.Args.AMHwySkims, Perf.Args.MDHwySkims}
    pa_file = Perf.Args.[DC Summary]
    grav_file = Perf.Args.[Grav_Combined]
    
    //Matrix indices matter - specified here
    skm_idx = {"ZoneID", "ZoneID"} //row/col index
    trp_idx = {,} //row/col index (null to use default/only index)
    
    //Format strings for data columns
    Tables = null
    Tables2 = null
    
    //Open trip distribution results in memory
    //pa_mat = OpenMatrix(pa_file, )
    //pa_curs = CreateMatrixCurrencies(pa_mat, trp_idx[1], trp_idx[2], )
    rpt_pers = {"Daily"} + pkop_pers
    dim TRIPS_per[rpt_pers.length]
    dim TRIPS_dy[purps.length] //Array to accumulate daily trips
    
    for _per = 1 to pkop_pers.length do
        per = pkop_pers[_per]
    
        //Open period skim matrix
        //skm_mat = OpenMatrix(skm_files[_per], )
        //skm_cur = CreateMatrixCurrency(skm_mat, "SP_and_Terminal", skm_idx[1], skm_idx[2], )
        
        //Calculate trip length frequency distributions
        PerPurps = null
        for p in purps do
            PerPurps = PerPurps + {per+"_"+p}
        end
        
        t = SplitPath(pa_file)
        tlfd_file = t[1] + t[2] + "TLFD_"+per+".bin"
        Opts = null
        Opts.Tables = PerPurps
        Opts.[Skim Index] = skm_idx
        Opts.[Trip Index] = trp_idx
        ok = UT.CalcTLFD(pa_file, skm_files[_per], "SP_and_Terminal", tlfd_file, Opts)
        if !ok then Return()
        
        //Close matrix
        //pa_mat = null
        //pa_curs = null
        //trip_curs = null
        
        //Create TLFD Charts and tables
        
        //Load from TLFD
        tlfd_vw = OpenTable("TLFD", "FFB", {tlfd_file})
        Vs = GetDataVectors(tlfd_vw+"|", {"BIN"}+PerPurps, )
        BINS = Vs[1]
        BINS_lim = SubVector(BINS, 1, max_plot_time)
        TRIPS = Subarray(Vs, 2, )
        
        //Accumulate daily TRIPS
        for ii = 1 to TRIPS.length do
            TRIPS_dy[ii] = nz(TRIPS_dy[ii]) + nz(TRIPS[ii])
        end
        
        CloseView(tlfd_vw)
        if !Verbose then UT.Delete(tlfd_file)
        
        //Save for report
        TRIPS_per[_per+1] = CopyArray(TRIPS) //Daily is first, so _per+1
        
    end //for _per
    
    //Add daily trips into array of distributions
    TRIPS_per[1] = CopyArray(TRIPS_dy)
    
    for _per = 1 to rpt_pers.length do
        per = rpt_pers[_per]
    
        TRIPS = CopyArray(TRIPS_per[_per])
        
        //Get percentages, limit to intended scope
        dim PCTS[TRIPS.length]
        dim PCTS_lim[TRIPS.Length]
        dim TRIPS_lim[TRIPS.Length]
        for ii = 1 to TRIPS.length do
            PCTS[ii] = nz(TRIPS[ii] / VectorStatistic(TRIPS[ii], "Sum", ))
            TRIPS_lim[ii] = SubVector(TRIPS[ii], 1, max_plot_time)
            PCTS_lim[ii] = SubVector(PCTS[ii], 1, max_plot_time)
        end
        
        
        //Chart
        CH = null
        CH.Name = "Trip Length Frequency Distribution ("+per+")"
        CH.Footnote = "Click the legend to show/hide trip purposes"
        CH.Chart.CanvasID = "tlfd_chart_"+per
        CH.Chart.Type = "line"
        CH.Chart.Labels = String(BINS_lim - 1) + "-" + String(BINS_lim)
        CH.Chart.Data = PCTS_lim
        CH.Chart.Width = 800
        CH.Chart.Height = 400
        CH.Chart.Names = purps
        CH.Chart.XAxis = "Travel Time (min)"
        CH.Chart.YAxis = "Percent of Trips"
        
        Tables = Tables + {CopyArray(CH)}
        if _per = 1 then Tables2 = Tables2 + {CopyArray(CH)}
        
        //... and table
        TOT = 0 //all purposes
        for ii = 1 to TRIPS.length do
            TOT = TOT + nz(TRIPS[ii])
        end
        dim Data[TRIPS.length]
        for ii = 1 to Data.length do
            Data[ii] = V2A(TRIPS[ii])
        end
        Data = Data + {V2A(TOT)}
        Data = TransposeArray(Data)
        TB = null
        TB.Name = "Trip Length Frequency Distribution Table ("+per+")"
        TB.Section2 = "Data Table"
        TB.Table.RowNames = V2A(String(BINS - 1) + "-" + String(BINS))
        TB.Table.ColNames = {"Time (min)"} + purps + {"Total"}
        TB.Table.TableData = Data
        
        Tables = Tables + {TB}

    end //_per
    
    //Truck TLFD
    grav_mat = OpenMatrix(grav_file, )
    trk_purps = Subarray(GetMatrixCoreNames(grav_mat), 1, 3)  //only use the first 3 cores (exclude airport)
    
    t = SplitPath(grav_file)
    tlfd_file = t[1] + t[2] + "TLFD_Truck.bin"
    Opts = null
    Opts.Tables = trk_purps
    Opts.[Skim Index] = skm_idx
    Opts.[Trip Index] = trp_idx
    ok = UT.CalcTLFD(grav_file, skm_files[2], "SP_and_Terminal", tlfd_file, Opts) //skm_file[2] = OP for trucks
    if !ok then Return()
    
    //Create TLFD Charts and tables
    
    //Load from TLFD
    tlfd_vw = OpenTable("TLFD", "FFB", {tlfd_file})
    Vs = GetDataVectors(tlfd_vw+"|", {"BIN"}+trk_purps, )
    BINS = Vs[1]
    BINS_lim = SubVector(BINS, 1, max_plot_time)
    TRIPS = Subarray(Vs, 2, )
    
    CloseView(tlfd_vw)
    if !Verbose then UT.Delete(tlfd_file)
    
    //Get percentages, limit to intended scope
    dim PCTS[TRIPS.length]
    dim PCTS_lim[TRIPS.Length]
    dim TRIPS_lim[TRIPS.Length]
    for ii = 1 to TRIPS.length do
        PCTS[ii] = nz(TRIPS[ii] / VectorStatistic(TRIPS[ii], "Sum", ))
        TRIPS_lim[ii] = SubVector(TRIPS[ii], 1, max_plot_time)
        PCTS_lim[ii] = SubVector(PCTS[ii], 1, max_plot_time)
    end
    
    //Chart
    CH = null
    CH.Name = "Trip Length Frequency Distribution (Trucks)"
    CH.Footnote = "Click the legend to show/hide trip purposes"
    CH.Chart.CanvasID = "tlfd_chart_truck"
    CH.Chart.Type = "line"
    CH.Chart.Labels = String(BINS_lim - 1) + "-" + String(BINS_lim)
    CH.Chart.Data = PCTS_lim
    CH.Chart.Width = 800
    CH.Chart.Height = 400
    CH.Chart.Names = trk_purps
    CH.Chart.XAxis = "Travel Time (min)"
    CH.Chart.YAxis = "Percent of Trips"
    
    Tables = Tables + {CopyArray(CH)}
    Tables2 = Tables2 + {CopyArray(CH)}
    
    //... and table
    TOT = 0 //all purposes
    for ii = 1 to TRIPS.length do
        TOT = TOT + nz(TRIPS[ii])
    end
    dim Data[TRIPS.length]
    for ii = 1 to Data.length do
        Data[ii] = V2A(TRIPS[ii])
    end
    Data = Data + {V2A(TOT)}
    Data = TransposeArray(Data)
    TB = null
    TB.Name = "Trip Length Frequency Distribution Table (Trucks)"
    TB.Section2 = "Data Table"
    TB.Table.RowNames = V2A(String(BINS - 1) + "-" + String(BINS))
    TB.Table.ColNames = {"Time (min)"} + trk_purps + {"Total"}
    TB.Table.TableData = Data
    
    Tables = Tables + {TB}
    
    

    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)
    
    Return(True)
EndMacro

// *************************************************************************************************
// Mode Choice
Macro "RPT Mode Choice" (Perf)

    mc_file = Perf.Args.[Mode Summary]
    purps = Perf.Args.Purps
    
    Modes = {"LOC", "PRM", "MIX"}   // List of transit modes
    AccessModes = {"WLK", "PNR", "KNR"}
    
    //Open the MC Summary view
    t = SplitPath(mc_file)
    mc_vw = OpenTable(t[3], "FFB", {mc_file})
    SetView(mc_vw)
    
    //Create summary tables object
    Tables = null
    Tables2 = null
    
    //Define fields to summarize (for details, before adding expressions)
    AllFields = GetFields(mc_vw, "All")
    AllFields = AllFields[1]
    SumFields = ArrayExclude(AllFields, {"PERIOD", "PURP", "INC", "VEH"})
    Flds = null
    for f in SumFields do
        Flds = Flds + {{f, "SUM"}}
    end
    
    
    // =========== Simplified ===========
    ReducedFlds = {'[Drive Alone]', '[Shared Ride 2]', '[Shared Ride 3+]'} + Modes + {'Walk', 'Bike'}
    ReducedSpecs = null
    for f in ReducedFlds do
        ReducedSpecs = ReducedSpecs + {{f, "SUM"}}
    end
    
    //Sum up transit modes
    for mod in Modes do
        sums = null
        for acc in AccessModes do
            sums = sums + {'nz([' + acc + " " + mod + '])'}
        end
        exp = JoinStrings(sums, ' + ')
        CreateExpression(mc_vw, mod, exp, )
    
    end

    //Table marginal Opts
    MargOpts = null
    MargOpts.Marginals = True
    MargOpts.SortRows = purps
    
    PctOpts = null
    PctOpts.Marginals = True
    PctOpts.Percents = True
    PctOpts.SortRows = purps
    
    
    PctOnlyOpts = null
    PctOnlyOpts.Percents = True
    PctOnlyOpts.SortRows = purps
    
    SortOnlyOpts = null
    SortOnlyOpts.SortRows = purps
    
    pers = {"DY", "PK", "OP"}
    per_names = {"Daily", "Peak", "Off-Peak"}
    
    
    // ===== Summaries by period =====
    for _per = 1 to pers.length do
        per = pers[_per]
        per_name = per_names[_per]
        
        //Simple
        if per = "DY" then do
            SelectAll("per")
        end else do
            SelectByQuery("per", "Several", "Select * Where PERIOD = '"+per+"'", )
        end
        agg_vw = AggregateTable("tmpAgg", mc_vw+"|per", "MEM", "tmpAgg", "PURP", ReducedSpecs, )
        TB = null
        TB.Section1 = per_name
        TB.Name = per_name + " Mode Choice"
        TB.Table = Perf.ViewToTable(agg_vw, MargOpts)
        TB.Footnote = "*HBSC trips are reduced to account for school bus trips, not shown."
        Tables = Tables + {CopyArray(TB)}
        
        //General Report
        if _per = 1 then do
            TB.Section1 = null
            Tables2 = Tables2 + {CopyArray(TB)}
        end
        
        //Simple Percents
        TB = null
        TB.Section1 = per_name
        TB.Name = per_name + " Mode Choice (Percents)"
        TB.Table = Perf.ViewToTable(agg_vw, PctOpts)
        TB.Table.Formats = "*0.0%"
        Tables = Tables + {CopyArray(TB)}
        
        //General Report
        if _per = 1 then do
            TB.Section1 = null
            Tables2 = Tables2 + {CopyArray(TB)}
        end
        
        //Chart
        tmp = Perf.ViewToTable(agg_vw, PctOnlyOpts) //percents, no
        ChartData = TransposeArray(tmp.TableData)  //use the % shares, no marginals

        CH = null
        CH.Name = per_name + " Mode Chocie Chart"
        CH.Section1 = per_name
        CH.Chart.CanvasID = "mode_choice_chart_"+per
        CH.Chart.Type = 'stacked'
        CH.Chart.Labels = tmp.RowNames
        CH.Chart.Data = ChartData
        CH.Chart.Names = Subarray(tmp.ColNames, 2, )  //remove purp name
        CH.Chart.Width = 800
        CH.Chart.YAxis = "Share of Trips"
        CH.Chart.YMax = 1
        Tables = Tables + {CopyArray(CH)}
        
        //General Report
        if _per = 1 then do
            CH.Section1 = null
            Tables2 = Tables2 + {CopyArray(CH)}
        end
        
        //Detail
        agg_vw = AggregateTable("tmpPK", mc_vw+"|per", "MEM", "tmpPK", "PURP", Flds, )
        TB = null
        TB.Section1 = per_name
        TB.Section2 = "Additional Details"
        TB.Name = per_name + " Mode Choice (Detailed)"
        TB.Table = Perf.ViewToTable(agg_vw, MargOpts)
        Tables = Tables + {CopyArray(TB)}
        
        CloseView(agg_vw)
    end //_per


    // =========== Detailed ===========
    
    //Write the complete MC summary table (additional details)
    
    //Re-open segment view to clear old expression fields
    CloseView(mc_vw)
    t = SplitPath(mc_file)
    mc_vw = OpenTable(t[3], "FFB", {mc_file})
    SetView(mc_vw)
    
    segment_exp = 'PERIOD+"_" + PURP + "_i" + String(INC) + "v"+String(VEH)'
    
    //Add SEGMENT at the beginning of the list of fields to export
    {ExpFlds, } = GetFields(mc_vw, "All")
    ExpFlds = {"SEGMENT"} + ArrayExclude(ExpFlds, {'PERIOD', 'PURP', 'INC', 'VEH'})
    
    //Add the SEGMENT field, then export to a memory view
    CreateExpression(mc_vw, "SEGMENT", segment_exp, )
    mem_mc_vw = ExportView(mc_vw+"|", "MEM", mc_vw, ExpFlds, )
    
    //Add to the report
    TB = null
    TB.Section1 = "Segmented"
    TB.Name = "Segmented Mode Choice Results (Detailed)"
    TB.Table = Perf.ViewToTable(mem_mc_vw, MargOpts)
    
    CloseView(mc_vw)
    CloseView(mem_mc_vw)
    
    Tables = Tables + {CopyArray(TB)}
    
    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)
    
    Return(True)

EndMacro
// *************************************************************************************************
// &&& Time Periods and Loading Factors
Macro "RPT Time Periods & Loading Factors" (Perf)
    
	shared UT
	
	//Define files
	periods = Perf.Args.HwyPeriods
	period_def = {"3:00 AM - 6:29 AM", "6:29 AM - 8:59 AM", "9:00 AM - 2:29 PM", "2:29 PM - 6:29 PM", "6:29 PM - 2:59 AM"}
	loading_fac = Perf.Args.[Speed Capacity Table] 
	
	dim Table[2]
	Table[1] = period_def
	fac_array = null
	
	//read loading factors
	loading_vw = OpenTable("Loading Factors", "FFB", {loading_fac})
    Vs = GetDataVectors(loading_vw+"|", { "EA_HrAdj", "AM_HrAdj", "MD_HrAdj", "PM_HrAdj", "EV_HrAdj"}, {{"Return Options Array", "True"}})
	
    for II = 1 to Vs.length do
	    fac = Vs[II][2][1] // read in peak hour to peak period factor
		fac_1 = 1/fac // calculate inverse
		fac_array = fac_array + {fac_1}
	end
	
	Table[2] = fac_array
    
    CloseView(loading_vw)
	
	//Save tables for writing
    TableArray = null
    TableArray2 = null
    
    ColNames = {"Period",
                 "Description",
                 "Loading Factor"}
	
	Table = TransposeArray(Table)
    
		
	//Write table
	TB = null
    TB.Name = "Time Periods & Loading Factors"
    TB.Table.TableData = CopyArray(Table)
	TB.Table.RowNames = periods
    TB.Table.ColNames = ColNames
	TB.Table.Formats = "*,0.00"
    TB.Table.Class = "dataframe no-last-any"
    
    TableArray = TableArray + {CopyArray(TB)}
    
    TableArray2 = TableArray2 + {CopyArray(TB)}
    
    Perf.fp = Perf.fp2
    Perf.WriteTables(TableArray2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(TableArray)
	
	RunMacro("G30 File Close All")
    Return(True)
	
EndMacro
// *************************************************************************************************
// &&& Assigned Vehicle Trips
Macro "RPT Assigned Trip Summary" (Perf)

    shared UT

    //Summary area - areas = {name, query}
    areas = Perf.ActiveAreas("Zones", True) //Always summarize all areas

    //Define files
    periods = Perf.Args.HwyPeriods //+ {"DY"} //Add daily to period list
    od_files = UT.Expand(Perf.Args.[OD Trip Tables])

    sed_file = Perf.Args.[TAZ Land Use Data] //Balanced PA file to read AT / Summary area info
    
    //Dimension array to hold data: Table[juris][per][row][typ (col)]     - 5 rows for 5 summary lines
    //dim Tables[juris_info.length, periods.length+1, 5, mat_cores.length+1] !!! hardcode 6 cores + 1 = 7
    
    dim Tables[areas.length, periods.length+1, 5, 7]
    
    //Add matrix indices for each jurisdiction
    sed_vw = OpenTable("SED", "CSV", {sed_file,})
    SetView(sed_vw)
    
    //Summarize by O and D in each jurisdiction
    CreateProgressBar("Sorting Trips", "False")
    progtot2 = areas.length*periods.length*6 //!!! hardocde, 6 matrix cores
    progcount = 0
    for area = 1 to areas.length do //by jurisdiction
        for per = 1 to periods.length do //by time of day, but Total does not need a separate loop
            mat = UT.OpenMatrixMem(od_files[per])
            
            //mat_cores = GetMatrixCoreNames(mat)
            // use this ordered list of classes instead as GetMatrixCoreNames(mat) gives alphabtically sorted vector from an OMX matrix
			mat_cores = Perf.Info.Class

            //Get rid of old indices
            on notfound goto next
                DeleteMatrixIndex(mat, areas[area][1])
            next:
            on notfound default
        
            cnt = SelectByQuery("Local", "Several", areas[area][2],)
            if cnt > 0 then do
                CreateMatrixIndex(areas[area][1], mat, "Both", sed_vw+"|Local", "zoneid", )

                typsum = {0,0,0,0,0}  //zeros for five rows: Sum of all trip types
                for typ = 1 to mat_cores.length do //by class
                    progcount = progcount + 1
                    prog = r2i((progcount/progtot2) * 100)
                    UpdateProgressBar("Sorting Trips", prog)
                
                    //Intrazonal trips
                    cur = CreateMatrixCurrency(mat, mat_cores[typ], areas[area][1], areas[area][1], )
                    v = GetMatrixVector(cur, {{"Diagonal", "Row"}})
                    s = VectorStatistic(v, "sum",)
                    
                    //For loop jurisdiction, period and type:
                    Tables[area][per][1][typ] = s
                    //Running total: all periods
                    Tables[area][periods.length+1][1][typ] = nz(Tables[area][periods.length+1][1][typ]) + s
                    //Running toal: all types
                    Tables[area][per][1][mat_cores.length+1] = nz(Tables[area][per][1][mat_cores.length+1]) + s
                    //Running total: all periods and types
                    Tables[area][periods.length+1][1][mat_cores.length+1] = nz(Tables[area][periods.length+1][1][mat_cores.length+1]) + s
                    
                    //Total Trips: Origin in juris
                    //!!! !!! !!! !!! !!! 
                    //cur = CreateMatrixCurrency(mat, mat_cores[typ], areas[area][1], area_info[5][1], )
                    cur = CreateMatrixCurrency(mat, mat_cores[typ], areas[area][1], , )
                    
                    v = GetMatrixVector(cur, {{"Marginal", "Row Sum"}})
                    s = VectorStatistic(v, "sum",)
                    Tables[area][per][3][typ] = s
                    Tables[area][periods.length+1][3][typ] = nz(Tables[area][periods.length+1][3][typ]) + s
                    Tables[area][per][3][mat_cores.length+1] = nz(Tables[area][per][3][mat_cores.length+1]) + s
                    Tables[area][periods.length+1][3][mat_cores.length+1] = nz(Tables[area][periods.length+1][3][mat_cores.length+1]) + s
                    
                    
                    //Total intrazonal origin trips (total minus intrazonal)
                    s = Tables[area][per][3][typ] - Tables[area][per][1][typ]
                    Tables[area][per][2][typ] = s
                    Tables[area][periods.length+1][2][typ] = nz(Tables[area][periods.length+1][2][typ]) + s
                    Tables[area][per][2][mat_cores.length+1] = nz(Tables[area][per][2][mat_cores.length+1]) + s
                    Tables[area][periods.length+1][2][mat_cores.length+1] = nz(Tables[area][periods.length+1][2][mat_cores.length+1]) + s
                    
                    //Total Trips: Destination in juris
                    cur = CreateMatrixCurrency(mat, mat_cores[typ], , areas[area][1], )
                    
                    v = GetMatrixVector(cur, {{"Marginal", "Row Sum"}})
                    s = VectorStatistic(v, "sum",)
                    Tables[area][per][5][typ] = s
                    Tables[area][periods.length+1][5][typ] = nz(Tables[area][periods.length+1][5][typ]) + s
                    Tables[area][per][5][mat_cores.length+1] = nz(Tables[area][per][5][mat_cores.length+1]) + s
                    Tables[area][periods.length+1][5][mat_cores.length+1] = nz(Tables[area][periods.length+1][5][mat_cores.length+1]) + s
                    
                    //Total intrazonal destination trips (total minus intrazonal)
                    s = Tables[area][per][5][typ] - Tables[area][per][1][typ]
                    Tables[area][per][4][typ] = s
                    Tables[area][periods.length+1][4][typ] = nz(Tables[area][periods.length+1][4][typ]) + s
                    Tables[area][per][4][mat_cores.length+1] = nz(Tables[area][per][4][mat_cores.length+1]) + s
                    Tables[area][periods.length+1][4][mat_cores.length+1] = nz(Tables[area][periods.length+1][4][mat_cores.length+1]) + s
					
					cur = null
                end //end loop over types
            end //if selection finds any records
        end //end loop over periods
        
        //Add a daily table
        tmp = CopyArray(Tables[area][1])
        for per = 2 to periods.length do //start at 2, since we've copied 1
        
            for ii = 1 to tmp.length do
                for jj = 1 to tmp[ii].length do
                    tmp[ii][jj] = nz(tmp[ii][jj]) + Tables[area][per][ii][jj]
                end
            end
        end
        Tables[area] = Tables[area] + {CopyArray(tmp)}
        
    end //end loop over jurisdictions
    DestroyProgressBar()
    
    //Save tables for writing
    TableArray = null
    TableArray2 = null
    
    RowNames = {"Intrazonal Trips",
                 "Interzonal Origins",
                 "Total Origins",
                 "Interzonal Destinations",
                 "Total Dest."}
    
    periods_dy = periods + {"Daily"}
    
    for _area = 1 to areas.length do
        {areaName, areaQRY, areaField, areaValue} = areas[_area]
		
		//Write daily tables first
		TB = null
        TB.Name = "Assigned Vehicle Trips - " + periods_dy[periods_dy.length]
        TB.Name = TB.Name + ' <span class="grey">('+areaName+')</span>'
        TB.Section1 = areaName
        TB.Table.TableData = CopyArray(Tables[_area][periods_dy.length])
        TB.Table.RowNames = RowNames
        TB.Table.ColNames = mat_cores + {"Total"}
        TB.Table.Formats = "*,0."
        TB.Table.Class = "dataframe no-last-any"
        
        TableArray = TableArray + {CopyArray(TB)}
        
        if _area = 1 then do
            TB.Section1 = null
            TableArray2 = TableArray2 + {CopyArray(TB)}
        end
		
        for _per = 1 to periods_dy.length-1 do
    
            TB = null
            TB.Name = "Assigned Vehicle Trips - " + periods_dy[_per]
            TB.Name = TB.Name + ' <span class="grey">('+areaName+')</span>'
            TB.Section1 = areaName
            TB.Table.TableData = CopyArray(Tables[_area][_per])
            TB.Table.RowNames = RowNames
            TB.Table.ColNames = mat_cores + {"Total"}
            TB.Table.Formats = "*,0."
            TB.Table.Class = "dataframe no-last-any"
            
            TableArray = TableArray + {CopyArray(TB)}
            
            if _area = 1 then do
                TB.Section1 = null
                TableArray2 = TableArray2 + {CopyArray(TB)}
            end
        
        end //_per
    end //_area
    
    Perf.fp = Perf.fp2
    Perf.WriteTables(TableArray2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(TableArray)
    
    /*
    FinTables = null
    FinTableNames = null
    for _area = 1 to areas.length do
        for _per = 1 to per_info.length do
            FinTables = FinTables + {Tables[_area][_per]}
            SubHeaders = SubHeaders + {areas[_area][1]}
            FinTableNames = FinTableNames + {"Assigned Vehicle Trips - " + per_info[_per]}
        end
    end
    
    //Define row and column headers:
    Opts = null
    Opts.RowNames = {"Intrazonal Trips",
                     "Interzonal Origins",
                     "Total Origins",
                     "Interzonal Destinations",
                     "Total Dest."}
    Opts.ColNames = trip_typ + {"Total"} 
    Opts.SubHeaders = SubHeaders
    Opts.TablesPerPage = 4 //!!! !!! writing the four time periods on the same page
    
    Perf.WriteTables(FinTables, FinTableNames, Opts)
*/
    //quit:
    RunMacro("G30 File Close All")
    Return(True)
EndMacro //End of Assigned Trips Summary

// *************************************************************************************************
// Assignment - AM
Macro "RPT AM Vehicle Assignment" (Perf)

    ok = RunMacro("RPT Vehicle Assignment", Perf, "AM")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

// *************************************************************************************************
// Assignment - PM
Macro "RPT PM Vehicle Assignment" (Perf)

    ok = RunMacro("RPT Vehicle Assignment", Perf, "PM")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

// *************************************************************************************************
// Assignment - MD
Macro "RPT MD Vehicle Assignment" (Perf)

    ok = RunMacro("RPT Vehicle Assignment", Perf, "MD")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

// *************************************************************************************************
// Assignment - EV
Macro "RPT EV Vehicle Assignment" (Perf)

    ok = RunMacro("RPT Vehicle Assignment", Perf, "EV")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

// *************************************************************************************************
// Assignment - EA
Macro "RPT EA Vehicle Assignment" (Perf)

    ok = RunMacro("RPT Vehicle Assignment", Perf, "EA")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

// *************************************************************************************************
// Assignment - DY
Macro "RPT DY Vehicle Assignment" (Perf)


    shared UT

    //FT and AT information
    ft_no = UT.Values(Perf.Info.FT)  //Returns a list of numbers only
    at_no = UT.Values(Perf.Info.AT)
	veh_classes = Perf.Info.Class // vehicle classes considered in the model (SOV, HOV2, HOV3, LT, MT, HT)

    //Summary area - areas = {name, query}
    areas = Perf.ActiveAreas("Network")  //Can be Network or Zones
    
    //Define files
    dbd_file = Perf.Args.[Highway DB]
    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", "DY", )
    
    //Define period names
    per = "DY"
	per2 = "Daily"
    
    //Dimension arrays to hold data: TableXXX[area][ft(row)][at(col)]
    dim TablesVMT[areas.length]
    dim TablesVHT[areas.length]
    dim TablesSPD[areas.length]
    TableGroup = {TablesVMT, TablesVHT, TablesSPD}
    NameGroup = {"Vehicle Miles Traveled", "Vehicle Hours Traveled", "Assigned Travel Speeds"}
    FormatGroup = {"*0,.", "*0,.","*0.0"}
                  
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    
    //Open and join link flows
    flow_vw = OpenTable("Flow", "FFB", {flow_file,})
    join_vw = JoinViews("Network+Flow", link_lyr+".ID", flow_vw+".ID1", )
    
    //Detect VMT name
    {FlowFields, } = GetFields(flow_vw, )
    if ArrayPosition(FlowFields, {"AB_VMT"}, ) > 0 then vmt_name = "M"
    else vmt_name = "_Dist_"
    
    //Compute formula fields
    SetView(join_vw)
	
    
    // ======= Summarize by County =======
    //Load data from view
    {FTv, COUNTYv, VMTv, VHTv} = GetDataVectors(join_vw+"|", 
                                           {"FT", "COUNTY",
                                           "TOT_V"+vmt_name+"T", "TOT_VHT"}, )
                                           
    //Compute cross-class with marginals
    Opts = null
    Opts.ColList = V2A(Vector(Perf.Info.Counties.length, "Long", {{"Sequence", 1, 1}}))
    
    dim TablesCounty[3]
    TablesCounty[1] = Perf.CrossTab(FTv, COUNTYv, VMTv, True, Opts)
    TablesCounty[2] = Perf.CrossTab(FTv, COUNTYv, VHTv, True, Opts)
    
    TablesCounty[3] = CopyArray(TablesCounty[1]) //To be filled with VMT / VHT
    
    //Compute speeds (VMT/VHT)
    for ii = 1 to TablesCounty[1].length do
        for jj = 1 to TablesCounty[1][ii].length do
            TablesCounty[3][ii][jj] = TablesCounty[1][ii][jj] / zn(TablesCounty[2][ii][jj], )
        end //jj
    end //ii
		  
    // ======= loop over summary areas =======
    for _area = 1 to areas.length do
        area_name = areas[_area][1]
        area_qry = areas[_area][2]
        SetView(link_lyr)
        //Do not report disabled links
        setcount = SelectByQuery("SummaryArea", "Several", 
                                 "Select * Where FT > 0", )
        setcount = SelectByQuery("SummaryArea", "Subset", area_qry, )
        //Only summarize if links are selected
        if setcount > 0 then do

            //Load data from view
            {FTv, ATv, VMTv, VHTv} = GetDataVectors(join_vw+"|SummaryArea", 
                                                   {"FT", "AT",
                                                   "TOT_V"+vmt_name+"T", "TOT_VHT"}, )
                                  
            //Math
            //(None needed)
                                  
            //Compute cross-class with marginals
            TablesVMT[_area] = Perf.CrossTab(FTv, ATv, VMTv, True)
            TablesVHT[_area] = Perf.CrossTab(FTv, ATv, VHTv, True)
            TablesSPD[_area] = CopyArray(TablesVMT[_area]) //To be filled with VMT / VHT
            
            //Compute speeds (VMT/VHT)
            for ii = 1 to TablesVMT[_area].length do
                for jj = 1 to TablesVMT[_area][ii].length do
                    TablesSPD[_area][ii][jj] = TablesVMT[_area][ii][jj] / zn(TablesVHT[_area][ii][jj], )
                end //jj
            end //ii
                                  
        end //end if summary flag = 1 and setcount > 0
    end //end loop over summary areas
	
	CloseView(join_vw)
	CloseView(flow_vw)
	
	// ======= Summarize by Class =======
	//Load data from view - loop over periods to calculate total VMT and VHT by vehicle class
	periods = Perf.Args.HwyPeriods
    dim TablesClass[TableGroup.length, ft_no.length, veh_classes.length]
	
	//Initialize
	for i = 1 to TablesClass.length do
	    for _ft = 1 to ft_no.length do
		    for _class = 1 to veh_classes.length do
			     TablesClass[i][_ft][_class] = 0
		    end
	    end
    end
	     
	
	for _ft = 1 to ft_no.length do
	    ft = ft_no[_ft]
		SetLayer(link_lyr)
		cnt_valid = SelectByQuery("Set", "Several","Select * where FT = " + i2s(ft))
	    for _class = 1 to veh_classes.length do
			veh_class = veh_classes[_class]
			
			if veh_class = "SOV" then veh_class = "DRIVEALONE"
			if veh_class = "HOV2" then veh_class = "SHARED2"
			if veh_class = "HOV3" then veh_class = "SHARED3"
			//if veh_class = "Light Truck" then veh_class = "LIGHT_TRUCK"
			//if veh_class = "Medium Truck" then veh_class = "MEDIUM_TRUCK"
			//if veh_class = "Heavy Truck" then veh_class = "HEAVY_TRUCK"
			
			for _per = 1 to periods.length do
			    period = periods[_per]
			    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", period, )
			    flow_vw = OpenTable("Flow", "FFB", {flow_file,})
                join_vw = JoinViews("Network+Flow", link_lyr+".ID", flow_vw+".ID1", )
	            if Upper(Right(veh_class, 5)) = "TRUCK" then do
                {FTv, LENGTHv, AB_TIMEv, BA_TIMEv, AB_FLOWv, BA_FLOWv} = GetDataVectors(join_vw+"|Set", 
                                                   {"FT", "Length", flow_vw+".AB_Time", flow_vw+".BA_Time",
                                                   "[AB_Flow_"+veh_class+"]", "[BA_Flow_"+veh_class+"]"}, )
		        end
		        else do
		        {FTv, LENGTHv, AB_TIMEv, BA_TIMEv, AB_FLOWv, BA_FLOWv} = GetDataVectors(join_vw+"|Set", 
                                                   {"FT", "Length", flow_vw+".AB_Time", flow_vw+".BA_Time",
                                                   "AB_Flow_"+veh_class, "BA_Flow_"+veh_class}, )
		        end
		        
		        VMT = nz(AB_FLOWv) * nz(LENGTHv) + nz(BA_FLOWv) * nz(LENGTHv)
		        VHT = (nz(AB_FLOWv) * nz(AB_TIMEv) + nz(BA_FLOWv) * nz(BA_TIMEv)) / 60
		        TablesClass[1][_ft][_class] = TablesClass[1][_ft][_class] + VectorStatistic(VMT, "Sum", )
		        TablesClass[2][_ft][_class] = TablesClass[2][_ft][_class] + VectorStatistic(VHT, "Sum", )
				CloseView(join_vw)
				CloseView(flow_vw)
			end //period
		end //class
	end //ft
	
	//Add marginals
	TablesClass[1]  = Perf.Marginals(TablesClass[1])
	TablesClass[2]  = Perf.Marginals(TablesClass[2])
    TablesClass[3]  = Perf.Marginals(TablesClass[3])
	
	//Compute speeds (VMT/VHT)
    for ii = 1 to TablesClass[1].length do
        for jj = 1 to TablesClass[1][ii].length do
            TablesClass[3][ii][jj] = TablesClass[1][ii][jj] / zn(TablesClass[2][ii][jj], )
        end //jj
    end ///ii
	
    CloseView(link_lyr)
    
    
    //Organize tables for writing
    Tables = null    
    Tables2 = null    
    
    //Summary By County
    for jj = 1 to TableGroup.length do
        TB = null
        TB.Section1 = "By County"
        TB.Name = NameGroup[jj]  + ' <span class="grey">('+per2+', By County)</span>' 
        TB.Table.ColNames = Perf.Info.Counties + {"Total"}
        TB.Table.TableData = TablesCounty[jj]
        TB.Table.Formats = FormatGroup[jj]
    
        Tables = Tables + {CopyArray(TB)}
        Tables2 = Tables2 + {CopyArray(TB)}
    end
	
	//Summary By Class
	for jj = 1 to TableGroup.length do
        TB = null
        TB.Section1 = "By Class"
        TB.Name = NameGroup[jj]  + ' <span class="grey">('+per2+', By Vehicle Class)</span>' 
        TB.Table.ColNames = Perf.Info.Class + {"Total"}
        TB.Table.TableData = TablesClass[jj]
        TB.Table.Formats = FormatGroup[jj]
    
        Tables = Tables + {CopyArray(TB)}
        Tables2 = Tables2 + {CopyArray(TB)}
    end
    
    //By summary area
    for ii = 1 to areas.length do
        //Tables
        for jj = 1 to TableGroup.length do
            TB = null
            TB.Section1 = areas[ii][1]
            TB.Name = NameGroup[jj]  + ' <span class="grey">('+per2+', '+areas[ii][1]+')</span>' 
            
            TB.Table.TableData = TableGroup[jj][ii]
            TB.Table.Formats = FormatGroup[jj]
            
            Tables = Tables + {CopyArray(TB)}
        end
        
    end
    
    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)
    
    RunMacro("G30 File Close All")
    Return(True)
    
EndMacro

// *************************************************************************************************
// Vehcile Assignment Summary - by period (per = "DY", "AM", "PM", "MD", "EA", "EV" only, case sensitive)
Macro "RPT Vehicle Assignment" (Perf, per)

    shared UT

    //FT and AT information
    ft_no = UT.Values(Perf.Info.FT)  //Returns a list of numbers only
    at_no = UT.Values(Perf.Info.AT)
	veh_classes = Perf.Info.Class // vehicle classes considered in the model (SOV, HOV2, HOV3, LT, MT, HT)

    //Summary area - areas = {name, query}
    areas = Perf.ActiveAreas("Network")  //Can be Network or Zones
    
    //Define files
    dbd_file = Perf.Args.[Highway DB]
    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", per, )
    
    //Define period names
    if per = "DY" then do
        per2 = "Daily"
    end else do
        per2 = per + " Peak Period"
    end
    
    //Dimension arrays to hold data: TableXXX[area][ft(row)][at(col)]
    dim TablesVMT[areas.length]
    dim TablesVHT[areas.length]
    dim TablesSPD[areas.length]
    TableGroup = {TablesVMT, TablesVHT, TablesSPD}
    NameGroup = {"Vehicle Miles Traveled", "Vehicle Hours Traveled", "Assigned Travel Speeds"}
    FormatGroup = {"*0,.", "*0,.","*0.0"}
                  
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    
    //Open and join link flows
    flow_vw = OpenTable("Flow", "FFB", {flow_file,})
    join_vw = JoinViews("Network+Flow", link_lyr+".ID", flow_vw+".ID1", )
    
    //Detect VMT name
    {FlowFields, } = GetFields(flow_vw, )
    if ArrayPosition(FlowFields, {"AB_VMT"}, ) > 0 then vmt_name = "M"
    else vmt_name = "_Dist_"
    
    //Compute formula fields
    SetView(join_vw)
	
    
    // ======= Summarize by County =======
    //Load data from view
    {FTv, COUNTYv, VMTv, VHTv} = GetDataVectors(join_vw+"|", 
                                           {"FT", "COUNTY",
                                           "TOT_V"+vmt_name+"T", "TOT_VHT"}, )
                                           
    //Compute cross-class with marginals
    Opts = null
    Opts.ColList = V2A(Vector(Perf.Info.Counties.length, "Long", {{"Sequence", 1, 1}}))
    
    dim TablesCounty[3]
    TablesCounty[1] = Perf.CrossTab(FTv, COUNTYv, VMTv, True, Opts)
    TablesCounty[2] = Perf.CrossTab(FTv, COUNTYv, VHTv, True, Opts)
    
    TablesCounty[3] = CopyArray(TablesCounty[1]) //To be filled with VMT / VHT
    
    //Compute speeds (VMT/VHT)
    for ii = 1 to TablesCounty[1].length do
        for jj = 1 to TablesCounty[1][ii].length do
            TablesCounty[3][ii][jj] = TablesCounty[1][ii][jj] / zn(TablesCounty[2][ii][jj], )
        end //jj
    end //ii
	
	// ======= Summarize by Class =======
	//Load data from view
    dim TablesClass[TableGroup.length, ft_no.length, veh_classes.length]
	
	for _ft = 1 to ft_no.length do
	    ft = ft_no[_ft]
		SetLayer(link_lyr)
		cnt_valid = SelectByQuery("Set", "Several","Select * where FT = " + i2s(ft))
	    for _class = 1 to veh_classes.length do
			veh_class = veh_classes[_class]
						
			if veh_class = "SOV" then veh_class = "DRIVEALONE"
			if veh_class = "HOV2" then veh_class = "SHARED2"
			if veh_class = "HOV3" then veh_class = "SHARED3"
			//if veh_class = "Light Truck" then veh_class = "LIGHT_TRUCK"
			//if veh_class = "Medium Truck" then veh_class = "MEDIUM_TRUCK"
			//if veh_class = "Heavy Truck" then veh_class = "HEAVY_TRUCK"
			
	        if Upper(Right(veh_class, 5)) = "TRUCK" then do
            {FTv, LENGTHv, AB_TIMEv, BA_TIMEv, AB_FLOWv, BA_FLOWv} = GetDataVectors(join_vw+"|Set", 
                                               {"FT", "Length", "AB_" + per + "_HwyT", "BA_" + per + "_HwyT",
                                               "[AB_Flow_"+veh_class+"]", "[BA_Flow_"+veh_class+"]"}, )
		    end
		    else do
		    {FTv, LENGTHv, AB_TIMEv, BA_TIMEv, AB_FLOWv, BA_FLOWv} = GetDataVectors(join_vw+"|Set", 
                                               {"FT", "Length", "AB_" + per + "_HwyT", "BA_" + per + "_HwyT",
                                               "AB_Flow_"+veh_class, "BA_Flow_"+veh_class}, )
		    end
		    
		    VMT = nz(AB_FLOWv) * nz(LENGTHv) + nz(BA_FLOWv) * nz(LENGTHv)
		    VHT = (nz(AB_FLOWv) * nz(AB_TIMEv) + nz(BA_FLOWv) * nz(BA_TIMEv)) / 60
		    TablesClass[1][_ft][_class] = VectorStatistic(VMT, "Sum", )
		    TablesClass[2][_ft][_class] = VectorStatistic(VHT, "Sum", )
		end //class
	end //ft
	
	//Add marginals
	TablesClass[1]  = Perf.Marginals(TablesClass[1])
	TablesClass[2]  = Perf.Marginals(TablesClass[2])
    TablesClass[3]  = Perf.Marginals(TablesClass[3])
	
	//Compute speeds (VMT/VHT)
    for ii = 1 to TablesClass[1].length do
        for jj = 1 to TablesClass[1][ii].length do
            TablesClass[3][ii][jj] = TablesClass[1][ii][jj] / zn(TablesClass[2][ii][jj], )
        end //jj
    end ///ii
	  
    // ======= loop over summary areas =======
    for _area = 1 to areas.length do
        area_name = areas[_area][1]
        area_qry = areas[_area][2]
        SetView(link_lyr)
        //Do not report disabled links
        setcount = SelectByQuery("SummaryArea", "Several", 
                                 "Select * Where FT > 0", )
        setcount = SelectByQuery("SummaryArea", "Subset", area_qry, )
        //Only summarize if links are selected
        if setcount > 0 then do

            //Load data from view
            {FTv, ATv, VMTv, VHTv} = GetDataVectors(join_vw+"|SummaryArea", 
                                                   {"FT", "AT",
                                                   "TOT_V"+vmt_name+"T", "TOT_VHT"}, )
                                  
            //Math
            //(None needed)
                                  
            //Compute cross-class with marginals
            TablesVMT[_area] = Perf.CrossTab(FTv, ATv, VMTv, True)
            TablesVHT[_area] = Perf.CrossTab(FTv, ATv, VHTv, True)
            TablesSPD[_area] = CopyArray(TablesVMT[_area]) //To be filled with VMT / VHT
            
            //Compute speeds (VMT/VHT)
            for ii = 1 to TablesVMT[_area].length do
                for jj = 1 to TablesVMT[_area][ii].length do
                    TablesSPD[_area][ii][jj] = TablesVMT[_area][ii][jj] / zn(TablesVHT[_area][ii][jj], )
                end //jj
            end //ii
                                  
        end //end if summary flag = 1 and setcount > 0
    end //end loop over summary areas
    CloseView(link_lyr)
    
    
    //Organize tables for writing
    Tables = null    
    Tables2 = null    
    
    //Summary By County
    for jj = 1 to TableGroup.length do
        TB = null
        TB.Section1 = "By County"
        TB.Name = NameGroup[jj]  + ' <span class="grey">('+per2+', By County)</span>' 
        TB.Table.ColNames = Perf.Info.Counties + {"Total"}
        TB.Table.TableData = TablesCounty[jj]
        TB.Table.Formats = FormatGroup[jj]
    
        Tables = Tables + {CopyArray(TB)}
        Tables2 = Tables2 + {CopyArray(TB)}
    end
	
	//Summary By Class
	for jj = 1 to TableGroup.length do
        TB = null
        TB.Section1 = "By Class"
        TB.Name = NameGroup[jj]  + ' <span class="grey">('+per2+', By Vehicle Class)</span>' 
        TB.Table.ColNames = Perf.Info.Class + {"Total"}
        TB.Table.TableData = TablesClass[jj]
        TB.Table.Formats = FormatGroup[jj]
    
        Tables = Tables + {CopyArray(TB)}
        Tables2 = Tables2 + {CopyArray(TB)}
    end
    
    //By summary area
    for ii = 1 to areas.length do
        //Tables
        for jj = 1 to TableGroup.length do
            TB = null
            TB.Section1 = areas[ii][1]
            TB.Name = NameGroup[jj]  + ' <span class="grey">('+per2+', '+areas[ii][1]+')</span>' 
            
            TB.Table.TableData = TableGroup[jj][ii]
            TB.Table.Formats = FormatGroup[jj]
            
            Tables = Tables + {CopyArray(TB)}
        end
        
    end
    
    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)
    
    RunMacro("G30 File Close All")
    Return(True)
    
EndMacro
// *************************************************************************************************
// Assignment Validation - DY and sub-periods, vehicle classes
Macro "RPT DY Vehicle Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "DY", "ALL")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

Macro "RPT AM Vehicle Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "AM", "ALL")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

Macro "RPT PM Vehicle Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "PM", "ALL")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

Macro "RPT MD Vehicle Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "MD", "ALL")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

Macro "RPT EV Vehicle Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "EV", "ALL")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

Macro "RPT EA Vehicle Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "EA", "ALL")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

Macro "RPT Auto Light Truck Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "DY", "AUTO")
    if !ok then goto quit

    quit:
    Return(ok)


EndMacro

Macro "RPT Truck Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "DY", "TRK")
    if !ok then goto quit

    quit:
    Return(ok)


EndMacro

Macro "RPT Medium Truck Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "DY", "MTRK")
    if !ok then goto quit

    quit:
    Return(ok)

EndMacro

Macro "RPT Heavy Truck Validation" (Perf)

    ok = RunMacro("RPT Vehicle Validation", Perf, "DY", "HTRK")
    if !ok then goto quit

    quit:
    Return(ok)


EndMacro

// *************************************************************************************************
// Assignment Validation - by period (per = "DY", "AM", or "PM" only, case sensitive) and
//                         by vehicle class (veh = "ALL", "AUTO", "TRK", "MTRK", "HTRK"), case sensitve    
Macro "RPT Vehicle Validation" (Perf, per, veh)

    shared UT

    //FT and AT information
    ft_no = UT.Values(Perf.Info.FT)  //Returns a list of numbers only
    at_no = UT.Values(Perf.Info.AT)

    //Summary area - areas = {name, query}
    areas = Perf.ActiveAreas("Network")  //Can be Network or Zones
    
    //Define files
    dbd_file = Perf.Args.[Highway DB]
    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", per, )
    count_file = Perf.Args.[Count Table]
    
    //Define count field
    if per = "DY" then do
        if veh = "ALL" then do
          c_fld = "VAL_Count"
          per2 = "Daily"
        end else if veh = "AUTO" then do
          c_fld = "AADT_CAR"
          per2 = "Daily"
        end else if veh = "MTRK" then do
          c_fld = "AADT_SUT" 
          per2 = "Daily"
        end else if veh = "HTRK" then do
          c_fld = "AADT_MUT" 
          per2 = "Daily"
        end else if veh = "TRK" then do
          c_fld = "AADT_TRUCK" 
          per2 = "Daily"
        end
    end else if per = "AM" then do
        c_fld = "TOT_COUNT_AM"
        per2 = "AM Peak Period"
    end else if per = "PM" then do
        c_fld = "TOT_COUNT_PM"
        per2 = "PM Peak Period"
    end else if per = "MD" then do
        c_fld = "TOT_COUNT_MD"
        per2 = "Mid-Day Period"
    end else if per = "EV" then do
        c_fld = "TOT_COUNT_EV"
        per2 = "Evening Period"
    end else if per = "EA" then do
        c_fld = "TOT_COUNT_EA"
        per2 = "Overnight Period"
    end
    
    //Define tables to hold data
    dim tCount[areas.length]
    dim tVolsOnC[areas.length]
    dim tCountVMT[areas.length]
    dim tModVMT[areas.length]
    dim tCountOne[areas.length]
    dim tOne[areas.length]
    dim tSquareError[areas.length]
    
    //These are be computed based on above results
    dim tVolRatio[areas.length]
    dim tError[areas.length]
    dim tVMTRatio[areas.length]
    dim tRMSE[areas.length]
    dim tPRMSE[areas.length]
    dim tRMSEgrp[areas.length]
    dim Charts[areas.length]
    
    dim tSummary[areas.length]
    
    //Collect tables into an array - only include tables that are to be written
    MainTables = 5 //Number of tables to show in main group (not collapsed)
    VGTable = 5 //Table by volume group - differnt headers/footers
    TableGroup = {tVMTRatio, tVolRatio, tPRMSE, tRMSE, tRMSEgrp, tCountVMT, tModVMT, tCountOne, tOne}
    NameGroup = {"Modeled VMT / Count VMT", 
                "Modeled Volume / Count Volume",
                "Percent Root Mean Square Error", 
                "Root Mean Square Error",
                "RMSE by volume group",
                
                "Count VMT",
                "Modeled VMT on Links With Counts",
                "Number of Links with Counts",
                "Number of Links"}
                
    FormatGroup = {"*0.0%", "*0.0%", "*0.0%", "*0,.", "*0,.000", "*0,.", "*0,.", "*0,.", "*0,."}
    
    SummaryCols = {"Model/Count VMT", 
                   "Modeled/Count Volume",
                   "% RMSE", 
                   "RMSE"}
    
    //RMSE Volume Group cutpoints
    VolGrps = {1000, 5000, 10000, 20000, 30000, 50000, 100000}
   
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    
    //Join the count fields to the network
    t = SplitPath(count_file)
    count_vw = OpenTable(t[3], "FFB", {count_file})
    join1_vw = UT.AttachCounts(link_lyr, count_vw)
    
    //Open and join flows
    flow_vw = OpenTable("Flow", "FFB", {flow_file,})
    join_vw = JoinViews("Network+Counts+Flow", join1_vw+"."+link_lyr+".ID", flow_vw+".ID1", )
    
    if per = "AM" or per = "PM" or per = "MD" or per = "EV" or per = "EA" then do
        DirTable = RunMacro("Directional Split", Perf, per, join_vw)
    end else do
        DirTable = null
    end
    
    // ======= Summarize by County =======
    // NOTES: 
    //        - This code is largely duplicated here and again in the summary area loop
    //        - The RMSE by volume group table is not included in this section
    if veh = "ALL" then do
      {FTv, COUNTYv, COUNTv, FLOWv, LENGTHv} = GetDataVectors(join_vw+"|", 
        {"FT", "COUNTY", c_fld, "TOT_Flow", "Length"}, )
     end else if veh = "AUTO" then do
      {FTv, COUNTYv, COUNTv, ABv1_fld, ABv2_fld, ABv3_fld,
      ABv4_fld, BAv1_fld, BAv2_fld, BAv3_fld, BAv4_fld, 
      LENGTHv} = GetDataVectors(join_vw+"|", 
        {"FT", "COUNTY", c_fld, "AB_Flow_DRIVEALONE", "AB_Flow_SHARED2", "AB_Flow_SHARED3", 
        "AB_Flow_Light Truck", "BA_Flow_DRIVEALONE", "BA_Flow_SHARED2", 
        "BA_Flow_SHARED3", "BA_Flow_Light Truck", "Length"}, )
      FLOWv = ABv1_fld + ABv2_fld + ABv3_fld + ABv4_fld + BAv1_fld + BAv2_fld + BAv3_fld + BAv4_fld
    end else if veh = "MTRK" then do
      {FTv, COUNTYv, COUNTv, ABv1_fld, BAv1_fld, LENGTHv} = GetDataVectors(join_vw+"|", 
        {"FT", "COUNTY", c_fld, "AB_Flow_Medium Truck", "BA_Flow_Medium Truck", "Length"}, )
      FLOWv = ABv1_fld + BAv1_fld
     end else if veh = "HTRK" then do
      {FTv, COUNTYv, COUNTv, ABv1_fld, BAv1_fld, LENGTHv} = GetDataVectors(join_vw+"|", 
        {"FT", "COUNTY", c_fld, "AB_Flow_Heavy Truck", "BA_Flow_Heavy Truck", "Length"}, )
      FLOWv = ABv1_fld + BAv1_fld
     end else if veh = "TRK" then do
      {FTv, COUNTYv, COUNTv, ABv1_fld, ABv2_fld, BAv1_fld, BAv2_fld, LENGTHv} = GetDataVectors(join_vw+"|", 
        {"FT", "COUNTY", c_fld, "AB_Flow_Medium Truck", "AB_Flow_Heavy Truck", 
        "BA_Flow_Medium Truck", "BA_Flow_Heavy Truck", "Length"}, )
        FLOWv = ABv1_fld + ABv2_fld + BAv1_fld + BAv2_fld
     end 
    
    //Math
    VolsOnCv = if COUNTv > 0 then FLOWv else 0
    CountVMTv = if COUNTv > 0 then (COUNTv * LENGTHv) else 0
    ModVMTv = if COUNTv > 0 then (FLOWv * LENGTHv) else 0
    CountONEv = if COUNTv > 0 then 1 else 0
    ONEv = Vector(COUNTv.Length, "Long", {{"Constant", 1}})
    SqERRv = if COUNTv > 0 then Pow(FLOWv - COUNTv, 2) else 0
    PctSqERRv = if COUNTv > 0 then SqERRv / Pow(FLOWv, 2) else 0
    
    //Compute cross-class with marginals
    Opts = null
    Opts.ColList = V2A(Vector(Perf.Info.Counties.length, "Long", {{"Sequence", 1, 1}}))
    dim TablesCounty[2]

    cntyCount = Perf.CrossTab(FTv, COUNTYv, COUNTv, True, Opts)
    cntyVolsOnC = Perf.CrossTab(FTv, COUNTYv, VolsOnCv, True, Opts)
    cntyCountVMT = Perf.CrossTab(FTv, COUNTYv, CountVMTv, True, Opts)
    cntyModVMT = Perf.CrossTab(FTv, COUNTYv, ModVMTv, True, Opts)
    cntyCountOne = Perf.CrossTab(FTv, COUNTYv, CountONEv, True, Opts)
    
    cntyOne = Perf.CrossTab(FTv, COUNTYv, ONEv, True, Opts)
    cntySquareError = Perf.CrossTab(FTv, COUNTYv, SqERRv, True, Opts)
    
    //Compute additional tables based on totals by FT/AT
    dim cntyVolRatio[cntyCount.Length, cntyCount[1].Length]
    dim cntyVMTRatio[cntyCount.Length, cntyCount[1].Length]
    dim cntyRMSE[cntyCount.Length, cntyCount[1].Length]
    dim cntyPRMSE[cntyCount.Length, cntyCount[1].Length]
    for row = 1 to cntyCount.length do
        for col = 1 to cntyCount[1].length do
            cntyVolRatio[row][col] = cntyVolsOnC[row][col] / zn(cntyCount[row][col], 0.0001)
            cntyVMTRatio[row][col] = cntyModVMT[row][col] / zn(cntyCountVMT[row][col], 0.0001)
            
            cntyRMSE[row][col] = sqrt(cntySquareError[row][col] / zn(cntyCountOne[row][col] - 1, 0.0001))
            cntyPRMSE[row][col] = cntyRMSE[row][col] / zn(cntyCount[row][col] / zn(cntyCountOne[row][col], 0.0001), 0.0001)
            
        end //col
    end //row
    TablesCounty = {cntyVMTRatio, cntyVolRatio, cntyPRMSE, cntyRMSE, null, cntyCountVMT, cntyModVMT, cntyCountOne, cntyOne}
    
    //Create a summary table, last (total) column of selected tables
    sum_grp = {cntyVMTRatio, cntyVolRatio, cntyPRMSE, cntyRMSE}
    dim tmp[sum_grp.length]
    for ii = 1 to sum_grp.length do
        t = CopyArray(sum_grp[ii])
        t = t[t.length]
        tmp[ii] = CopyArray(t)
    end
    cntySummary = TransposeArray(tmp)
    
    
    // ======= loop over summary areas =======
    for _area = 1 to areas.length do
        area_name = areas[_area][1]
        area_qry = areas[_area][2]
        SetView(join_vw)
        setcount = SelectByQuery("Sel", "Several", "Select * where FT > 0", )
        setcount = SelectByQuery("Sel", "Subset", area_qry, )
        
        //Only summarize if links are selected
        if setcount > 0 then do
            //Load data from view
            if veh = "ALL" then do
              {FTv, ATv, COUNTv, FLOWv, LENGTHv} = GetDataVectors(join_vw+"|Sel", 
                {"FT", "AT", c_fld, "TOT_Flow", "Length"}, )
             end else if veh = "AUTO" then do
              {FTv, ATv, COUNTv, ABv1_fld, ABv2_fld, ABv3_fld,
              ABv4_fld, BAv1_fld, BAv2_fld, BAv3_fld, BAv4_fld, 
              LENGTHv} = GetDataVectors(join_vw+"|Sel", 
                {"FT", "AT", c_fld, "AB_Flow_DRIVEALONE", "AB_Flow_SHARED2", "AB_Flow_SHARED3", 
                "AB_Flow_Light Truck", "BA_Flow_DRIVEALONE", "BA_Flow_SHARED2", 
                "BA_Flow_SHARED3", "BA_Flow_Light Truck", "Length"}, )
              FLOWv = ABv1_fld + ABv2_fld + ABv3_fld + ABv4_fld + BAv1_fld + BAv2_fld + BAv3_fld + BAv4_fld
            end else if veh = "MTRK" then do
              {FTv, ATv, COUNTv, ABv1_fld, BAv1_fld, LENGTHv} = GetDataVectors(join_vw+"|Sel", 
                {"FT", "AT", c_fld, "AB_Flow_Medium Truck", "BA_Flow_Medium Truck", "Length"}, )
              FLOWv = ABv1_fld + BAv1_fld
             end else if veh = "HTRK" then do
              {FTv, ATv, COUNTv, ABv1_fld, BAv1_fld, LENGTHv} = GetDataVectors(join_vw+"|Sel", 
                {"FT", "AT", c_fld, "AB_Flow_Heavy Truck", "BA_Flow_Heavy Truck", "Length"}, )
              FLOWv = ABv1_fld + BAv1_fld
             end else if veh = "TRK" then do
              {FTv, ATv, COUNTv, ABv1_fld, ABv2_fld, BAv1_fld, BAv2_fld, LENGTHv} = GetDataVectors(join_vw+"|Sel", 
                {"FT", "AT", c_fld, "AB_Flow_Medium Truck", "AB_Flow_Heavy Truck", 
                "BA_Flow_Medium Truck", "BA_Flow_Heavy Truck", "Length"}, )
                FLOWv = ABv1_fld + ABv2_fld + BAv1_fld + BAv2_fld
             end
                               
            //Math
            VolsOnCv = if COUNTv > 0 then FLOWv else 0
            CountVMTv = if COUNTv > 0 then (COUNTv * LENGTHv) else 0
            ModVMTv = if COUNTv > 0 then (FLOWv * LENGTHv) else 0
            CountONEv = if COUNTv > 0 then 1 else 0
            ONEv = Vector(COUNTv.Length, "Long", {{"Constant", 1}})
            SqERRv = if COUNTv > 0 then Pow(FLOWv - COUNTv, 2) else 0
            PctSqERRv = if COUNTv > 0 then SqERRv / Pow(FLOWv, 2) else 0
            
            //RMSE Volume groups
            prev_grp = 0
            VolGRPv = Vector(ONEv.length, "Long", {{"Constant", 0}})
            VolGrpLabels = null
            VolGrpFmts = null
            for _vg = 1 to VolGrps.length do
                VolGRPv = if (COUNTv >= prev_grp and COUNTv < VolGrps[_vg]) then _vg else VolGRPv
                VolGrpLabels = VolGrpLabels + {Format(prev_grp, "*0,.") + " - " + Format(VolGrps[_vg], "*0,.")}
                prev_grp = VolGrps[_vg]
                VolGrpFmts = VolGrpFmts + {{"*,.", "*,.", "*.0%"}}
            end
            //Top end group
            _vg = VolGrps.length
            VolGRPv = if (COUNTv >= VolGrps[_vg]) then _vg+1 else VolGRPv
            VolGrpLabels = VolGrpLabels + {Format(VolGrps[_vg], "*0,.") + " and up", "All Links"}
            
            //Formats for &up and total rows
            VolGrpFmts = VolGrpFmts + {{"*,.", "*,.", "*.0%"}}
            VolGrpFmts = VolGrpFmts + {{"*,.", "*,.", "*.0%"}}
            
            //Compute cross-class with marginals
            tCount[_area] = Perf.CrossTab(FTv, ATv, COUNTv, True)
            tVolsOnC[_area] = Perf.CrossTab(FTv, ATv, VolsOnCv, True)
            tCountVMT[_area] = Perf.CrossTab(FTv, ATv, CountVMTv, True)
            tModVMT[_area] = Perf.CrossTab(FTv, ATv, ModVMTv, True)
            tCountOne[_area] = Perf.CrossTab(FTv, ATv, CountONEv, True)
            tOne[_area] = Perf.CrossTab(FTv, ATv, ONEv, True)
            tSquareError[_area] = Perf.CrossTab(FTv, ATv, SqERRv, True)
            
            vgOpts = null
            vgOpts.RowList = V2A(Vector(VolGrps.length+1, "Long", {{"Sequence", 1, 1}}))
            vgOpts.ColList = {1}
            
            vgCount = Perf.CrossTab(VolGRPv, ONEv, COUNTv, True, vgOpts)
            vgCountOne = Perf.CrossTab(VolGRPv, ONEv, CountONEv, True, vgOpts)
            vgSquareError = Perf.CrossTab(VolGRPv, ONEv, SqERRv, True, vgOpts)
            vgPctSqrError = Perf.CrossTab(VolGRPv, ONEv, PctSqERRv, True, vgOpts)
            
            //Compute additional tables based on totals by FT/AT
            dim tmpVolRatio[tCount[_area].Length, tCount[_area][1].Length]
            dim tmpVMTRatio[tCount[_area].Length, tCount[_area][1].Length]
            dim tmpRMSE[tCount[_area].Length, tCount[_area][1].Length]
            dim tmpPRMSE[tCount[_area].Length, tCount[_area][1].Length]
            for row = 1 to tCount[_area].length do
                for col = 1 to tCount[_area][1].length do
                    tmpVolRatio[row][col] = tVolsOnC[_area][row][col] / zn(tCount[_area][row][col], 0.0001)
                    tmpVMTRatio[row][col] = tModVMT[_area][row][col] / zn(tCountVMT[_area][row][col], 0.0001)
                    
                    tmpRMSE[row][col] = sqrt(tSquareError[_area][row][col] / zn(tCountOne[_area][row][col] - 1, 0.0001))
                    tmpPRMSE[row][col] = tmpRMSE[row][col] / zn(tCount[_area][row][col] / zn(tCountOne[_area][row][col], 0.0001), 0.0001)
                    
                end //col
            end //row
            
            //Percent RMSE by volume group
            dim tmpGrpRMSE[vgCount.length, 3]
            for row = 1 to vgCount.length do
                tmpGrpRMSE[row][1] = vgCountOne[row][1]
                tmpGrpRMSE[row][2] = sqrt(vgSquareError[row][1] / zn(vgCountOne[row][1] - 1, 0.0001))
                tmpGrpRMSE[row][3] = tmpGrpRMSE[row][2] / zn(vgCount[row][1] / zn(vgCountOne[row][1], 0.0001), 0.0001)
            end
            
            //Place the results in the overall tables by area
            tVolRatio[_area] = CopyArray(tmpVolRatio)
            tVMTRatio[_area] = CopyArray(tmpVMTRatio)
            tRMSE[_area] = CopyArray(tmpRMSE)
            tPRMSE[_area] = CopyArray(tmpPRMSE)
            
            tRMSEgrp[_area] = CopyArray(tmpGrpRMSE)
            
            //Create a summary table, last (total) column of selected tables
            sum_grp = {tVMTRatio[_area], tVolRatio[_area], tPRMSE[_area], tRMSE[_area]}
            dim tmp[sum_grp.length]
            for ii = 1 to sum_grp.length do
                t = TransposeArray(sum_grp[ii])
                t = t[t.length]
                tmp[ii] = CopyArray(t)
            end
            tSummary[_area] = TransposeArray(tmp)
            
            
            //Create a scatter chart
            dim data_fwy[2]
            dim data_art[2]
            dim data_oth[2]
            
            for ii = 1 to COUNTv.length do
                if COUNTv[ii] > 0 then do
                    if FTv[ii] <= 2 then do
                        data_fwy[1] = data_fwy[1] + {COUNTv[ii]}
                        data_fwy[2] = data_fwy[2] + {FLOWv[ii]}
                    end else if FTv[ii] <= 4 then do
                        data_art[1] = data_art[1] + {COUNTv[ii]}
                        data_art[2] = data_art[2] + {FLOWv[ii]}
                    end else do
                        data_oth[1] = data_oth[1] + {COUNTv[ii]}
                        data_oth[2] = data_oth[2] + {FLOWv[ii]}
                    end
                end //have count
            end
            
            Chart = null
            Chart.CanvasID = "scatterchart_" + area_name + "_" + per + "_" + veh
            Chart.Type = 'scatter'
            Chart.Names = {"Freeway", "Arterial", "Other"}
            Chart.Data = {data_fwy, data_art, data_oth}
            Chart.XAxis = "Count"
            Chart.YAxis = "Model Volume"
            Chart.Width = 500
            Chart.Height = 500
            
            Charts[_area] = CopyArray(Chart)
            
        end //if records were selected
    end //end loop over summary areas
    
    //Close views
    CloseView(join_vw)
    CloseView(join1_vw)
    CloseView(flow_vw)
    CloseView(count_vw)
	DropLayerFromWorkspace(link_lyr)
	DropLayerFromWorkspace(node_lyr)
    
    //Re-organize table arrays for report writing
    Tables = null
    
    if DirTable != null then do
        Tables = Tables + {CopyArray(DirTable)}
    end

    //Setup format array for summary table
    dim SummaryFormats[cntySummary.length]
    for ii = 1 to SummaryFormats.length do
        SummaryFormats[ii] = Subarray(FormatGroup, 1, SummaryCols.length)  //FormatGroup
    end
    
    //Summary By County
    
    //Summary Table
    TB = null
    TB.Section1 = "By County"
    TB.Name = 'Validation Summary <span class="grey">('+per2+', By County)</span>' 
    TB.Table.TableData = cntySummary
    TB.Table.Formats = SummaryFormats
    TB.Table.ColNames = SummaryCols
    TB.Table.RowNames = Perf.Info.Counties + {"Total"}
    TB.Table.Class = "dataframe no-last-col"
    
    Tables = Tables + {CopyArray(TB)}
    
    for jj = 1 to TableGroup.length do
    
        if jj != VGTable then do
        
            TB = null
            TB.Section1 = "By County"
            TB.Name = NameGroup[jj]  + ' <span class="grey">('+per2+', By County)</span>' 
            TB.Table.ColNames = Perf.Info.Counties + {"Total"}
            TB.Table.TableData = TablesCounty[jj]
            TB.Table.Formats = FormatGroup[jj]
        
            Tables = Tables + {CopyArray(TB)}
        end
    end
    
    
    //Setup format array for summary table
    dim SummaryFormats[tSummary[1].length]
    for ii = 1 to SummaryFormats.length do
        SummaryFormats[ii] = Subarray(FormatGroup, 1, SummaryCols.length)  //FormatGroup
    end
    for ii = 1 to areas.length do
        
        //Summary Table
        TB = null
        TB.Section1 = areas[ii][1]
        TB.Name = 'Validation Summary <span class="grey">('+per2+', '+areas[ii][1]+')</span>' 
        TB.Table.TableData = tSummary[ii]
        TB.Table.Formats = SummaryFormats
        TB.Table.ColNames = SummaryCols
        TB.Table.Class = "dataframe no-last-col"
        
        Tables = Tables + {CopyArray(TB)}
        
        //Tables
        for jj = 1 to TableGroup.length do
            TB = null
            TB.Section1 = areas[ii][1]
            if jj > MainTables then TB.Section2 = "Additional Details"
            TB.Name = NameGroup[jj]  + ' <span class="grey">('+per2+', '+areas[ii][1]+')</span>' 
            
            TB.Table.TableData = TableGroup[jj][ii]
            TB.Table.Formats = FormatGroup[jj]
            
            if jj = VGTable then do
                TB.Table.RowNames = VolGrpLabels
                TB.Table.ColNames = {"Volume Group", "Links", "RMSE", "% RMSE"}
                TB.Table.Formats = VolGrpFmts //override default with cell-specific array
            end

            Tables = Tables + {CopyArray(TB)}
        end
        
        //Scatter chart
        CH = null
        CH.Section1 = areas[ii][1]
        CH.Name = 'Scatter Plot' + ' <span class="grey">('+per2+', '+areas[ii][1]+')</span>' 
        CH.Chart = CopyArray(Charts[ii])
        Tables = Tables + {CopyArray(CH)}
    end
    
    Perf.WriteTables(Tables, {"HeaderClass":"validation"})
    
    Return(True)
    
EndMacro

// *************************************************************************************************
// Directional Split - by period (per = "AM", or "PM" only, case sensitive)
Macro "Directional Split" (Perf, per, join_vw)

    shared UT

    
    //Define count field
    if per = "AM" then do
        c_fld = "_COUNT_AM" //AB/BA prefix added below
        per2 = "AM Peak Period"
    end else if per = "PM" then do
        c_fld = "_COUNT_PM" //AB/BA prefix added below
        per2 = "PM Peak Period"
    end else if per = "MD" then do
        c_fld = "_COUNT_MD"
        per2 = "Mid-Day Period"
    end else if per = "EV" then do
        c_fld = "_COUNT_EV"
        per2 = "Evening Period"
    end else if per = "EA" then do
        c_fld = "_COUNT_EA"
        per2 = "Overnight Period"
    end else do
        Throw("Invalid period definition for Directional Split")
    end
    
    //Limit to links with AB and BA Counts
    SetView(join_vw)
    cnt = SelectByQuery("DirectionCheck", "Several", "Select * Where AB"+c_fld+" > 0 and BA"+c_fld+" > 0")
    if cnt = 0 then do
        Throw("No links found with Coutns in both directions")
    end
    
    // Summarize correct vs. reverse directional split
    {FTv, COUNTYv, ABCOUNTv, BACOUNTv, ABFLOWv, BAFLOWv, LENGTHv} = GetDataVectors(join_vw+"|DirectionCheck", 
    {"FT", "COUNTY", "AB"+c_fld, "BA"+c_fld, "AB_Flow", "BA_Flow", "Length"}, )
    DeleteSet("DirectionCheck")
    
    DirUK = if ABCOUNTv = BACOUNTv then 1 else 0
    DirOK = if (ABCOUNTv != BACOUNTv) and ((ABCOUNTv > BACOUNTv and ABFLOWv > BAFLOWv) or (ABCOUNTv < BACOUNTv and ABFLOWv < BAFLOWv)) then 1 else 0
    DirNO = if DirOK = 0 and DirUK = 0 then 1 else 0
    
    CountOK = VectorStatistic(DirOK, "Sum", )
    CountNO = VectorStatistic(DirNO, "Sum", )
    CountUN = VectorStatistic(DirUK, "Sum", )
    CountKnown = CountOK + CountNO
    PctOK = CountOK / CountKnown
    PctNO = CountNO / CountKnown
        
    tbl = {{CountOK, PctOK}, {CountNO, PctNO}, {CountUN, null}}
    fmt = {{"*,.", "*%.0"}, {"*,.", "*%.0"}, {"*,.", "*%.0"}}
    
    TB = null
    TB.Section1 = "Directional Split"
    TB.Name = 'Directional Split <span class="grey">('+per2+')</span>' 
    TB.Table.ColNames = {"Observations", "Percent"}
    TB.Table.RowNames = {"Correct Split", "Reversed Split", "No Data"}
    TB.Table.TableData = tbl
    TB.Table.Formats = fmt
    TB.Table.Class = "dataframe no-last-any"

    Return(TB)
    
EndMacro


// *************************************************************************************************
// CV Model Validation

Macro "RPT CV Model Validation" (Perf)

//Macro "SEMCOG CV Dashboard" (Args)
	shared UT, Scen
	// Create Commercial Vehicle Model Dashboard
        
 	staticCVM = Perf.Args.[UseStaticCVMTrips]
    	if staticCVM = 1 then do
        	ok = 1
        	return(ok)
    	end

    // CVM batch file and application path argument to be passed to it
    bat_file = Perf.Args.[CVM Batch File]
    r_dir = Perf.Args.[R_DIR]

	// Create a file of input and output file information
        paths_file = Substitute(bat_file, ".bat", ".txt", )
	cv_paths = OpenFile(paths_file, "w")
	// R library directory and pandoc directory
	WriteLine(cv_paths, Perf.Args.[R_LIBRARY])
	WriteLine(cv_paths, Perf.Args.[PANDOC_DIR])
	// Scenario name, description, input and output directories, iteration, and CV component name
	WriteLine(cv_paths, Perf.Args.Info.Name)
	WriteLine(cv_paths, Perf.Args.Info.[Input Directory])
	WriteLine(cv_paths, Perf.Args.Info.[Output Directory])
	WriteLine(cv_paths, string(Scen.Feedback.iteration))
	WriteLine(cv_paths, "CV Dashboard")
	// Whether to write the spreadsheet summary (TRUE), path to assignment outputs
	WriteLine(cv_paths, "TRUE")
	WriteLine(cv_paths, Perf.Args.[Highway Flows])
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

EndMacro


// ****************************************************************************************************************
// Screenline Summary
Macro "RPT Screenline" (Perf)

NextStep= "Screenline Report"
SetStatus(1, NextStep, )

    shared UT

    fwy_fts = {1, 2}   //Freeway, HOV, and Tollway FT numbers

    //Define files
    dbd_file = Perf.Args.[Highway DB]
    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", "DY", )
    count_file = Perf.Args.[Count Table]
   
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    
    //Join the count fields to the network
    t = SplitPath(count_file)
    count_vw = OpenTable(t[3], "FFB", {count_file})
    join1_vw = UT.AttachCounts(link_lyr, count_vw)
    
    //Load data from network
    flow_vw = OpenTable("Flows", "FFB", {flow_file,})
    join_vw = JoinViews("Network+Counts+Flow", join1_vw+"."+link_lyr+".ID", flow_vw+".ID1", )
    SetView(join_vw)
    SelectByQuery("Screens", "Several", "Select * where CL_ID != null", )
    {SCRLv, VOLv, FTv, CNTv} = GetDataVectors(join_vw+"|Screens", 
        {"CL_ID", "TOT_FLOW", "FT", "MAP_COUNT"}, ) //use MAP_COUNT, which includes counts that are not included in the validation stats.
    
    //Get list of unique screelines
    scrl_names = V2A(SortVector(SCRLv, {{"Unique", "True"}}))
    
    //Identify freeway links
    FWYv = Vector(FTv.Length, "Long", )
    for I = 1 to FTv.Length do
        FWYv[I] = if ArrayPosition(fwy_fts, {FTv[I]}, ) > 0 then 1 else 0
    end
    
    //Dimension arrays to hold data: [scrl][vol/count/percent/err/links/counts]
    dim TableTot[scrl_names.length, 6] 
    dim TableFwy[scrl_names.length, 6]
    dim TableOth[scrl_names.length, 6]
    
    for _scrl = 1 to scrl_names.length do
        scrl = scrl_names[_scrl]
        
        //All Links
        TableTot[_scrl][1] = VectorStatistic(if SCRLv = scrl then VOLv else 0, "Sum", )
        TableTot[_scrl][2] = VectorStatistic(if SCRLv = scrl then CNTv else 0, "Sum", )
        err = TableTot[_scrl][1] / zn(TableTot[_scrl][2], 0.0001)
        TableTot[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][5] = VectorStatistic(if (SCRLv = scrl) then 1 else 0, "Sum", )
        TableTot[_scrl][6] = VectorStatistic(if (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Freeway Links
        TableFwy[_scrl][1] = VectorStatistic(if FWYv and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableFwy[_scrl][2] = VectorStatistic(if FWYv and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableFwy[_scrl][1] / zn(TableFwy[_scrl][2], 0.0001)
        TableFwy[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableFwy[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableFwy[_scrl][5] = VectorStatistic(if FWYv and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableFwy[_scrl][6] = VectorStatistic(if FWYv and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Non-Freeway Links
        TableOth[_scrl][1] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableOth[_scrl][2] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableOth[_scrl][1] / zn(TableOth[_scrl][2], 0.0001)
        TableOth[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableOth[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableOth[_scrl][5] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableOth[_scrl][6] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
    end
    
    //Set up formats
    fmt_all = {"*,0.", "*,0.", "*0.00", "*0.0%", "*0.", "*0."}
    
    fmt1 = null
    for ii = 1 to scrl_names.length do
        fmt1 = fmt1 + {fmt_all}
    end
    
    cols = {"Model Volume", "Count Volume", "Model / Count", "Pct. Error", "Links", "Counts"}

    //Write The Tables
    Tables = null
    
    
    //All links
    TB = null
    TB.Name = "Screenlines (All Links)"
    TB.Table.TableData = TableTot
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Freeway Links)"
    TB.Table.TableData = TableFwy
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Non-Freeway Links)"
    TB.Table.TableData = TableOth
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    Perf.WriteTables(Tables, {"HeaderClass":"validation"})
    
//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
	
    RunMacro("G30 File Close All")
    Return(True)
	
//EndStep
EndMacro

// *************************************************************************************************
// Auto and Light Truck Screenline Summary
Macro "RPT Auto Light Truck Screenline" (Perf)

NextStep= "Auto and Light Truck Screenline Report"
SetStatus(1, NextStep, )

    shared UT

    fwy_fts = {1, 2}   //Freeway, HOV, and Tollway FT numbers

    //Define files
    dbd_file = Perf.Args.[Highway DB]
    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", "DY", )
    count_file = Perf.Args.[Count Table]
   
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    
    //Join the count fields to the network
    t = SplitPath(count_file)
    count_vw = OpenTable(t[3], "FFB", {count_file})
    join1_vw = UT.AttachCounts(link_lyr, count_vw)
    
    //Load data from network
    flow_vw = OpenTable("Flows", "FFB", {flow_file,})
    join_vw = JoinViews("Network+Counts+Flow", join1_vw+"."+link_lyr+".ID", flow_vw+".ID1", )
    SetView(join_vw)
    SelectByQuery("Screens", "Several", "Select * where CL_ID != null and CL_AUTO > 0", )
    
    {SCRLv, ABv1_fld, ABv2_fld, ABv3_fld, ABv4_fld, BAv1_fld, BAv2_fld, BAv3_fld, BAv4_fld, FTv, CNTv} = GetDataVectors(join_vw+"|Screens", 
        {"CL_ID", "AB_Flow_DRIVEALONE", "AB_Flow_SHARED2", "AB_Flow_SHARED3", "AB_Flow_Light Truck", "BA_Flow_DRIVEALONE", "BA_Flow_SHARED2", "BA_Flow_SHARED3", "BA_Flow_Light Truck", "FT", "CL_AUTO"}, ) 
    VOLAv = ABv1_fld + ABv2_fld + ABv3_fld + BAv1_fld + BAv2_fld + BAv3_fld
    VOLLv = ABv4_fld + BAv4_fld
    VOLv = ABv1_fld + ABv2_fld + ABv3_fld + ABv4_fld + BAv1_fld + BAv2_fld + BAv3_fld + BAv4_fld

    //Get list of unique screelines
    scrl_names = V2A(SortVector(SCRLv, {{"Unique", "True"}}))
    
    //Identify freeway links
    FWYv = Vector(FTv.Length, "Long", )
    for I = 1 to FTv.Length do
        FWYv[I] = if ArrayPosition(fwy_fts, {FTv[I]}, ) > 0 then 1 else 0
    end
    
    //Dimension arrays to hold data: [scrl][vol1/vol2/pct2/volt/count/percent/err/links/counts]
    dim TableTot[scrl_names.length, 9] 
    dim TableFwy[scrl_names.length, 9]
    dim TableOth[scrl_names.length, 9]
    
    for _scrl = 1 to scrl_names.length do
        scrl = scrl_names[_scrl]
        
        //All Links
        TableTot[_scrl][1] = VectorStatistic(if SCRLv = scrl then VOLAv else 0, "Sum", )
        TableTot[_scrl][2] = VectorStatistic(if SCRLv = scrl then VOLLv else 0, "Sum", )
        pct2 = TableTot[_scrl][2] / zn(TableTot[_scrl][1] + TableTot[_scrl][2], 0.0001)
        TableTot[_scrl][3] = Format(pct2, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][4] = VectorStatistic(if SCRLv = scrl then VOLv else 0, "Sum", )
        TableTot[_scrl][5] = VectorStatistic(if SCRLv = scrl then CNTv else 0, "Sum", )
        err = TableTot[_scrl][4] / zn(TableTot[_scrl][5], 0.0001)
        TableTot[_scrl][6] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][7] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][8] = VectorStatistic(if (SCRLv = scrl) then 1 else 0, "Sum", )
        TableTot[_scrl][9] = VectorStatistic(if (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Freeway Links
        TableFwy[_scrl][1] = VectorStatistic(if FWYv and (SCRLv = scrl) then VOLAv else 0, "Sum", )
        TableFwy[_scrl][2] = VectorStatistic(if FWYv and (SCRLv = scrl) then VOLLv else 0, "Sum", )
        pct2 = TableFwy[_scrl][2] / zn(TableFwy[_scrl][1] + TableFwy[_scrl][2], 0.0001)
        TableFwy[_scrl][3] = Format(pct2, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        TableFwy[_scrl][4] = VectorStatistic(if FWYv and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableFwy[_scrl][5] = VectorStatistic(if FWYv and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableFwy[_scrl][4] / zn(TableFwy[_scrl][5], 0.0001)
        TableFwy[_scrl][6] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableFwy[_scrl][7] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableFwy[_scrl][8] = VectorStatistic(if FWYv and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableFwy[_scrl][9] = VectorStatistic(if FWYv and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Non-Freeway Links
        TableOth[_scrl][1] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then VOLAv else 0, "Sum", )
        TableOth[_scrl][2] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then VOLLv else 0, "Sum", )
        pct2 = TableOth[_scrl][2] / zn(TableOth[_scrl][1] + TableOth[_scrl][2], 0.0001)
        TableOth[_scrl][3] = Format(pct2, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        TableOth[_scrl][4] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableOth[_scrl][5] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableOth[_scrl][4] / zn(TableOth[_scrl][5], 0.0001)
        TableOth[_scrl][6] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableOth[_scrl][7] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableOth[_scrl][8] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableOth[_scrl][9] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
    end
    
    //Set up formats
    fmt_all = {"*,0.", "*,0.", "*0.0%", "*,0.", "*,0.", "*0.00", "*0.0%", "*0.", "*0."}
    
    fmt1 = null
    for ii = 1 to scrl_names.length do
        fmt1 = fmt1 + {fmt_all}
    end
    
    cols = {"Auto Volume", "Light Truck Volume", "Pct. Light Trucks", "Model Volume", "Count Volume", "Model / Count", "Pct. Error", "Links", "Counts"}

    //Write The Tables
    Tables = null
    
    
    //All links
    TB = null
    TB.Name = "Screenlines (All Links)"
    TB.Table.TableData = TableTot
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Freeway Links)"
    TB.Table.TableData = TableFwy
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Non-Freeway Links)"
    TB.Table.TableData = TableOth
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    Perf.WriteTables(Tables, {"HeaderClass":"validation"})
    
//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
	
    RunMacro("G30 File Close All")
    Return(True)
	
//EndStep
EndMacro


// *************************************************************************************************
// Medium and Heavy Truck Screenline Summary
Macro "RPT Truck Screenline" (Perf)

NextStep= "Medium and Heavy Truck Screenline Report"
SetStatus(1, NextStep, )

    shared UT

    fwy_fts = {1, 2}   //Freeway, HOV, and Tollway FT numbers

    //Define files
    dbd_file = Perf.Args.[Highway DB]
    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", "DY", )
    count_file = Perf.Args.[Count Table]
   
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    
    //Join the count fields to the network
    t = SplitPath(count_file)
    count_vw = OpenTable(t[3], "FFB", {count_file})
    join1_vw = UT.AttachCounts(link_lyr, count_vw)
    
    //Load data from network
    flow_vw = OpenTable("Flows", "FFB", {flow_file,})
    join_vw = JoinViews("Network+Counts+Flow", join1_vw+"."+link_lyr+".ID", flow_vw+".ID1", )
    SetView(join_vw)
    SelectByQuery("Screens", "Several", "Select * where CL_ID != null and CL_MTRK > 0 and CL_HTRK > 0", )
    
    {SCRLv, ABv1_fld, ABv2_fld, BAv1_fld, BAv2_fld, FTv, CNTv1, CNTv2} = GetDataVectors(join_vw+"|Screens", 
        {"CL_ID", "AB_Flow_Medium Truck", "AB_Flow_Heavy Truck", "BA_Flow_Medium Truck", "BA_Flow_Heavy Truck", "FT", "CL_MTRK", "CL_HTRK"}, ) 
    VOLv = ABv1_fld + ABv2_fld + BAv1_fld + BAv2_fld
    CNTv = CNTv1 + CNTv2
    
    //Get list of unique screelines
    scrl_names = V2A(SortVector(SCRLv, {{"Unique", "True"}}))
    
    //Identify freeway links
    FWYv = Vector(FTv.Length, "Long", )
    for I = 1 to FTv.Length do
        FWYv[I] = if ArrayPosition(fwy_fts, {FTv[I]}, ) > 0 then 1 else 0
    end
    
    //Dimension arrays to hold data: [scrl][vol/count/percent/err/links/counts]
    dim TableTot[scrl_names.length, 6] 
    dim TableFwy[scrl_names.length, 6]
    dim TableOth[scrl_names.length, 6]
    
    for _scrl = 1 to scrl_names.length do
        scrl = scrl_names[_scrl]
        
        //All Links
        TableTot[_scrl][1] = VectorStatistic(if SCRLv = scrl then VOLv else 0, "Sum", )
        TableTot[_scrl][2] = VectorStatistic(if SCRLv = scrl then CNTv else 0, "Sum", )
        err = TableTot[_scrl][1] / zn(TableTot[_scrl][2], 0.0001)
        TableTot[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][5] = VectorStatistic(if (SCRLv = scrl) then 1 else 0, "Sum", )
        TableTot[_scrl][6] = VectorStatistic(if (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Freeway Links
        TableFwy[_scrl][1] = VectorStatistic(if FWYv and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableFwy[_scrl][2] = VectorStatistic(if FWYv and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableFwy[_scrl][1] / zn(TableFwy[_scrl][2], 0.0001)
        TableFwy[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableFwy[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableFwy[_scrl][5] = VectorStatistic(if FWYv and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableFwy[_scrl][6] = VectorStatistic(if FWYv and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Non-Freeway Links
        TableOth[_scrl][1] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableOth[_scrl][2] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableOth[_scrl][1] / zn(TableOth[_scrl][2], 0.0001)
        TableOth[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableOth[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableOth[_scrl][5] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableOth[_scrl][6] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
    end
    
    //Set up formats
    fmt_all = {"*,0.", "*,0.", "*0.00", "*0.0%", "*0.", "*0."}
    
    fmt1 = null
    for ii = 1 to scrl_names.length do
        fmt1 = fmt1 + {fmt_all}
    end
    
    cols = {"Model Volume", "Count Volume", "Model / Count", "Pct. Error", "Links", "Counts"}

    //Write The Tables
    Tables = null
    
    
    //All links
    TB = null
    TB.Name = "Screenlines (All Links)"
    TB.Table.TableData = TableTot
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Freeway Links)"
    TB.Table.TableData = TableFwy
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Non-Freeway Links)"
    TB.Table.TableData = TableOth
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    Perf.WriteTables(Tables, {"HeaderClass":"validation"})
    
//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
	
    RunMacro("G30 File Close All")
    Return(True)
	
//EndStep
EndMacro

// *************************************************************************************************
// Medium Truck Screenline Summary
Macro "RPT Medium Truck Screenline" (Perf)

NextStep= "Medium Truck Screenline Report"
SetStatus(1, NextStep, )

    shared UT

    fwy_fts = {1, 2}   //Freeway, HOV, and Tollway FT numbers

    //Define files
    dbd_file = Perf.Args.[Highway DB]
    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", "DY", )
    count_file = Perf.Args.[Count Table]
   
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    
    //Join the count fields to the network
    t = SplitPath(count_file)
    count_vw = OpenTable(t[3], "FFB", {count_file})
    join1_vw = UT.AttachCounts(link_lyr, count_vw)
    
    //Load data from network
    flow_vw = OpenTable("Flows", "FFB", {flow_file,})
    join_vw = JoinViews("Network+Counts+Flow", join1_vw+"."+link_lyr+".ID", flow_vw+".ID1", )
    SetView(join_vw)
    SelectByQuery("Screens", "Several", "Select * where CL_ID != null and CL_MTRK > 0", )
    
    {SCRLv, ABv_fld, BAv_fld, FTv, CNTv} = GetDataVectors(join_vw+"|Screens", 
        {"CL_ID", "AB_Flow_Medium Truck", "BA_Flow_Medium Truck", "FT", "CL_MTRK"}, ) 
    VOLv = ABv_fld + BAv_fld
    
    //Get list of unique screelines
    scrl_names = V2A(SortVector(SCRLv, {{"Unique", "True"}}))
    
    //Identify freeway links
    FWYv = Vector(FTv.Length, "Long", )
    for I = 1 to FTv.Length do
        FWYv[I] = if ArrayPosition(fwy_fts, {FTv[I]}, ) > 0 then 1 else 0
    end
    
    //Dimension arrays to hold data: [scrl][vol/count/percent/err/links/counts]
    dim TableTot[scrl_names.length, 6] 
    dim TableFwy[scrl_names.length, 6]
    dim TableOth[scrl_names.length, 6]
    
    for _scrl = 1 to scrl_names.length do
        scrl = scrl_names[_scrl]
        
        //All Links
        TableTot[_scrl][1] = VectorStatistic(if SCRLv = scrl then VOLv else 0, "Sum", )
        TableTot[_scrl][2] = VectorStatistic(if SCRLv = scrl then CNTv else 0, "Sum", )
        err = TableTot[_scrl][1] / zn(TableTot[_scrl][2], 0.0001)
        TableTot[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][5] = VectorStatistic(if (SCRLv = scrl) then 1 else 0, "Sum", )
        TableTot[_scrl][6] = VectorStatistic(if (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Freeway Links
        TableFwy[_scrl][1] = VectorStatistic(if FWYv and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableFwy[_scrl][2] = VectorStatistic(if FWYv and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableFwy[_scrl][1] / zn(TableFwy[_scrl][2], 0.0001)
        TableFwy[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableFwy[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableFwy[_scrl][5] = VectorStatistic(if FWYv and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableFwy[_scrl][6] = VectorStatistic(if FWYv and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Non-Freeway Links
        TableOth[_scrl][1] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableOth[_scrl][2] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableOth[_scrl][1] / zn(TableOth[_scrl][2], 0.0001)
        TableOth[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableOth[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableOth[_scrl][5] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableOth[_scrl][6] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
    end
    
    //Set up formats
    fmt_all = {"*,0.", "*,0.", "*0.00", "*0.0%", "*0.", "*0."}
    
    fmt1 = null
    for ii = 1 to scrl_names.length do
        fmt1 = fmt1 + {fmt_all}
    end
    
    cols = {"Model Volume", "Count Volume", "Model / Count", "Pct. Error", "Links", "Counts"}

    //Write The Tables
    Tables = null
    
    
    //All links
    TB = null
    TB.Name = "Screenlines (All Links)"
    TB.Table.TableData = TableTot
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Freeway Links)"
    TB.Table.TableData = TableFwy
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Non-Freeway Links)"
    TB.Table.TableData = TableOth
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    Perf.WriteTables(Tables, {"HeaderClass":"validation"})
    
//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
	
    RunMacro("G30 File Close All")
    Return(True)
	
//EndStep
EndMacro

// *************************************************************************************************
// Heavy Truck Screenline Summary
Macro "RPT Heavy Truck Screenline" (Perf)

NextStep= "Heavy Truck Screenline Report"
SetStatus(1, NextStep, )

    shared UT

    fwy_fts = {1, 2}   //Freeway, HOV, and Tollway FT numbers

    //Define files
    dbd_file = Perf.Args.[Highway DB]
    flow_file = Substitute(Perf.Args.[Highway Flows], "%PER_HWY%", "DY", )
    count_file = Perf.Args.[Count Table]
   
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    Perf.CalcNetFields(link_lyr)
    
    //Join the count fields to the network
    t = SplitPath(count_file)
    count_vw = OpenTable(t[3], "FFB", {count_file})
    join1_vw = UT.AttachCounts(link_lyr, count_vw)
    
    //Load data from network
    flow_vw = OpenTable("Flows", "FFB", {flow_file,})
    join_vw = JoinViews("Network+Counts+Flow", join1_vw+"."+link_lyr+".ID", flow_vw+".ID1", )
    SetView(join_vw)
    SelectByQuery("Screens", "Several", "Select * where CL_ID != null & CL_HTRK > 0", )
    
    {SCRLv, ABv_fld, BAv_fld, FTv, CNTv} = GetDataVectors(join_vw+"|Screens", 
        {"CL_ID", "AB_Flow_Heavy Truck", "BA_Flow_Heavy Truck", "FT", "CL_HTRK"}, ) 
    VOLv = ABv_fld + BAv_fld
    
    //Get list of unique screelines
    scrl_names = V2A(SortVector(SCRLv, {{"Unique", "True"}}))
    
    //Identify freeway links
    FWYv = Vector(FTv.Length, "Long", )
    for I = 1 to FTv.Length do
        FWYv[I] = if ArrayPosition(fwy_fts, {FTv[I]}, ) > 0 then 1 else 0
    end
    
    //Dimension arrays to hold data: [scrl][vol/count/percent/err/links/counts]
    dim TableTot[scrl_names.length, 6] 
    dim TableFwy[scrl_names.length, 6]
    dim TableOth[scrl_names.length, 6]
    
    for _scrl = 1 to scrl_names.length do
        scrl = scrl_names[_scrl]
        
        //All Links
        TableTot[_scrl][1] = VectorStatistic(if SCRLv = scrl then VOLv else 0, "Sum", )
        TableTot[_scrl][2] = VectorStatistic(if SCRLv = scrl then CNTv else 0, "Sum", )
        err = TableTot[_scrl][1] / zn(TableTot[_scrl][2], 0.0001)
        TableTot[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        TableTot[_scrl][5] = VectorStatistic(if (SCRLv = scrl) then 1 else 0, "Sum", )
        TableTot[_scrl][6] = VectorStatistic(if (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Freeway Links
        TableFwy[_scrl][1] = VectorStatistic(if FWYv and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableFwy[_scrl][2] = VectorStatistic(if FWYv and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableFwy[_scrl][1] / zn(TableFwy[_scrl][2], 0.0001)
        TableFwy[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableFwy[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableFwy[_scrl][5] = VectorStatistic(if FWYv and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableFwy[_scrl][6] = VectorStatistic(if FWYv and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
        //Non-Freeway Links
        TableOth[_scrl][1] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then VOLv else 0, "Sum", )
        TableOth[_scrl][2] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then CNTv else 0, "Sum", )
        err = TableOth[_scrl][1] / zn(TableOth[_scrl][2], 0.0001)
        TableOth[_scrl][3] = Format(err, "*0.00") //Format applies to HTML only, ColFormat applies to Excel
        TableOth[_scrl][4] = Format(err - 1, "*0.0%") //Format applies to HTML only, ColFormat applies to Excel
        
        TableOth[_scrl][5] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) then 1 else 0, "Sum", )
        TableOth[_scrl][6] = VectorStatistic(if FWYv=0 and (SCRLv = scrl) and (CNTv > 0) then 1 else 0, "Sum", )
        
    end
    
    //Set up formats
    fmt_all = {"*,0.", "*,0.", "*0.00", "*0.0%", "*0.", "*0."}
    
    fmt1 = null
    for ii = 1 to scrl_names.length do
        fmt1 = fmt1 + {fmt_all}
    end
    
    cols = {"Model Volume", "Count Volume", "Model / Count", "Pct. Error", "Links", "Counts"}

    //Write The Tables
    Tables = null
    
    
    //All links
    TB = null
    TB.Name = "Screenlines (All Links)"
    TB.Table.TableData = TableTot
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Freeway Links)"
    TB.Table.TableData = TableFwy
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    TB = null
    TB.Name = "Screenlines (Non-Freeway Links)"
    TB.Table.TableData = TableOth
    TB.Table.RowNames = scrl_names
    TB.Table.ColNames = cols
    TB.Table.Formats = fmt1
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    Perf.WriteTables(Tables, {"HeaderClass":"validation"})
    
//EndStep
NextStep= "Clean Up"
SetStatus(1, "@System0", )
	
    RunMacro("G30 File Close All")
    Return(True)
	
//EndStep
EndMacro

// *************************************************************************************************
// &&& Loaded Speed Summary
Macro "RPT Assignment Speed" (Perf)
    //Update progres bar
	
    area_info = Perf.SumArea
    
    shared UT

    //FT and AT information
    ft_no = UT.Values(Perf.Info.FT)  //Returns a list of numbers only
    at_no = UT.Values(Perf.Info.AT)
    
    //Summary area - areas = {name, query}
    areas = Perf.ActiveAreas("Network")  //Can be Network or Zones
    per_info = Perf.Args.Table.TOD.PerList.Value //period info

    //Define files
    dbd_file   =  Perf.Args.Output.INI.RdNetwork.Value
	flow_files = {Perf.Args.Output.ASN.FlowOP.Value,      //OP   - Must match per_info!!
                  Perf.Args.Output.ASN.FlowMD.Value,      //MD
				  Perf.Args.Output.ASN.FlowAM1.Value,     //AM
				  Perf.Args.Output.ASN.FlowPM1.Value,     //PM
				  Perf.Args.Output.PST.FlowDaily.Value } //daily
    
    //Dimension arrays to hold data: TableXXX[area][ft(row)][at(col)]
    dim SPDVMTt[areas.length, per_info.length+1, ft_no.length, at_no.length]    
    dim VMTt   [areas.length, per_info.length+1, ft_no.length, at_no.length]    
    dim Tables [areas.length, per_info.length+1, ft_no.length+1, at_no.length+1]  //per_info.length+1 for FF speeds
                                                                                                        //at and ft +1 for totals
    
    //Open dbd network
    RunMacro("TCB Add DB Layers", dbd_file,,)
    layers = RunMacro("TCB get DB line and node layers", dbd_file)
    node_lyr = layers[1]
    link_lyr = layers[2]
    
    for per = 1 to per_info.length+1 do  //+1 for free-flow speeds
        //use daily if doing free-flow speeds
        if per > per_info.length then do
            flow_vw = OpenTable("Flows", "FFB", {flow_files[per],})
            join_vw = JoinViews("Join", flow_vw+".ID1", link_lyr+".ID", )
        end    
        //Otherwise, load directly from chosen period
        else do
            flow_vw = OpenTable("Flows", "FFB", {flow_files[per],})
            join_vw = JoinViews("Join", flow_vw+".ID1", link_lyr+".ID", )
        end

        //Loop over summary areas
        for area = 1 to areas.length do
            SetView(join_vw)
            //if area_flag[area] = 1 and area_info[area][3] = 1 then setcount = SelectByQuery("SummaryArea", "Several", area_info[area][2], )
            //else setcount = 0
            
            expr2 = CreateExpression(join_vw, "NCHRPVMT", "(nz(AB_Flow_NCHRP)*nz(Length))+ (nz(BA_Flow_NCHRP)*nz(Length))", )  
            
            
            
            //Do not report disabled links
            setcount = SelectByQuery("SummaryArea", "Several", 
                                     "Select * Where FT > 0", )
            setcount = SelectByQuery("SummaryArea", "Subset", areas[area][2], )
            //Only summarize if links are selected
            //setcount = SelectByQuery("SummaryArea", "Several", areas[area][2], )
            if setcount > 0 then do

                FTv = GetDataVector(join_vw+"|SummaryArea", "FT", )
                ATv = GetDataVector(join_vw+"|SummaryArea", "AT", )
                //VMTv = GetDataVector(join_vw+"|SummaryArea", "TOT_VMT", )
                VMTv = GetDataVector(join_vw+"|SummaryArea", "NCHRPVMT", )
        
                if per > per_info.length then do //Get free-flow SpeedVMT
                    FFSPDv = GetDataVector(join_vw+"|SummaryArea", "FF_SPD", )
                    //FFVMTv = GetDataVector(join_vw+"|SummaryArea", "TOT_VMT", )
                    FFVMTv = GetDataVector(join_vw+"|SummaryArea", "NCHRPVMT", )
                    SPDVMTv= FFSPDv * FFVMTv
                    FFSPDv = null
                    FFVMTv = null
                end
                else do  //or congested SpeedVMT
					//!!! !!! !!! !!! didnot create cspeedvmt as part of combine flow
					//so using expression for now but has to confirm the usage
					//expr = CreateExpression(join_vw, "CSPEEDVMT", "(nz(AB_VMT)*nz(AB_Speed))+ (nz(BA_VMT)*nz(BA_Speed))", )
                    expr = CreateExpression(join_vw, "CSPEEDVMT", "(nz(AB_Flow_NCHRP)*nz(Length)*nz(AB_Speed_NCHRP))+ (nz(BA_Flow_NCHRP)*nz(Length)*nz(BA_Speed_NCHRP))", )
	                SPDVMTv = GetDataVector(join_vw+"|SummaryArea", "CSPEEDVMT", )
                end

                CreateProgressBar("Aggregating Data", "False")
                for I = 1 to FTv.length do
                    prog = r2i((I / FTv.length)*100)
                    UpdateProgressBar("Aggregating Data", prog)

                    ft = ArrayPosition(ft_no, {FTv[I]}, )
                    at = ArrayPosition(at_no, {ATv[I]}, )
                    
                    //Put values in the table
                    SPDVMTt[area][per][ft][at] = nz(SPDVMTt[area][per][ft][at]) + nz(SPDVMTv[I])
                    VMTt[area][per][ft][at] = nz(VMTt[area][per][ft][at]) + nz(VMTv[I])
                end //end loop over selected records
                DestroyProgressBar()
            end //end if summary flag = 1 and setcount > 0
            SPDVMTt[area][per] = Perf.Marginals(SPDVMTt[area][per])
            VMTt[area][per] = Perf.Marginals(VMTt[area][per])
            

        end //end loop over summary areas
        CloseView(join_vw)
        CloseView(flow_vw)
        
        //Divide sum(SPEEDVMT) / sum(VMT)
        for area = 1 to Tables.length do
            for ft = 1 to Tables[area][per].length do
                for at = 1 to Tables[area][per][ft].length do
                    if VMTt[area][per][ft][at] > 0 then do
                        Tables[area][per][ft][at] = SPDVMTt[area][per][ft][at] / VMTt[area][per][ft][at]
                    end
                end
            end
        end //end loop over area, ft, at
        
    end //end loop over periods
    
    //Write tables
    TableNames = null
	wTables = null   //Use wtables for the WriteTables function - Tables already used.
	fmt = null
    SubHeaders = null
	for area = 1 to areas.length do
        for per = 1 to per_info.length+1 do
            if per > per_info.length then do
                SubHeaders = SubHeaders + {areas[area][1]}
                TableNames = TableNames + {"Assignment Freeflow Speed Summary"}
                wTables = wTables + {Tables[area][per]}
                fmt = fmt + {"*0,.00"}
            end
            else do
                SubHeaders = SubHeaders + {areas[area][1]}
                TableNames = TableNames + {per_info[per] + " Loaded Speed Summary (VMT Weighted)" }
                wTables = wTables + {Tables[area][per]}
                fmt = fmt + {"*0,.00"}
            end
        end

	end

    Perf.WriteTables(wTables, TableNames, {{"SubHeaders" , SubHeaders}} ) 
    RunMacro("G30 File Close All")
    Return(True)
EndMacro

// ****************************************************************************************************************
// Transit Assignment Summary
//
Macro "RPT Transit Assignment" (Perf)
    
    //Define files
    rts_file = Perf.Args.[Route System]
	tdbd_file= Perf.Args.[Highway DB]

	onoff_file = Perf.Args.[Daily Transit OnOff Files]
	tflow_file = Perf.Args.[Daily Transit Flow Files]
	mc_file = Perf.Args.[Mode Summary] //To get total transit trips

    //Define Parameters
    Modes       = {"LOC", "PRM", "MIX"}   // List of transit modes
    AccessModes = {"WLK", "PNR", "KNR"}//Added for Transit Drive Egress AWalker Nov. 2016

		
NextStep = "Aggregate boarding data"
SetStatus(1, NextStep, )

    onoff_vw = OpenTable("OnOff", "FFB", {onoff_file}, )
    CreateExpression(onoff_vw, "XferOn", "nz(DirectTransferOn) + nz(WalkTransferOn)", )
    agg_onoff_vw = AggregateTable("OnOff_Agg", onoff_vw+"|", "MEM", null, "ROUTE", {{"On", "SUM"}, {"XferOn", "Sum"}}, {{"Missing as zero"}})
    CloseView(onoff_vw)
    
NextStep = "Aggregate flow data"
SetStatus(1, NextStep, )

    tflow_vw = OpenTable("OnOff", "FFB", {tflow_file}, )
    CreateExpression(tflow_vw, "PMT", "(To_MP - From_MP) * TransitFlow", )
    agg_tflow_vw = AggregateTable("Tflow_Agg", tflow_vw+"|", "MEM", null, "ROUTE", {{"PMT", "SUM"}}, {{"Missing as zero"}})
    CloseView(tflow_vw)
    
NextStep = "Load the Route System"
SetStatus(1, NextStep, )

	tdbd_info = GetDBInfo(tdbd_file)
    map = CreateMap("Route System", {{"Scope", tdbd_info[1]},{"Auto Project", "True"}})
    lyrs = AddRouteSystemLayer(map, "Route System", rts_file,)
    RunMacro("Set Default RS Style", lyrs, "True", "True")
    route_lyr = lyrs[1]
    stop_lyr  = lyrs[2]
	tnode_lyr = lyrs[4]
	tlink_lyr = lyrs[5]
    
    //Join to routes to match ID with name
    //Use a cascading join, Routes+OnOff+TFlow
    join1_vw = JoinViews("Routes+OnOff", route_lyr+".Route_ID", agg_onoff_vw+".ROUTE", )
    join_vw = JoinViews("Routes+OnOff+TFlow", join1_vw+".Route_ID", agg_tflow_vw+".ROUTE",  )
    
NextStep = "Get Data by Route Name"
SetStatus(1, NextStep, )

    //Load data into a table
    Data = GetDataVectors(join_vw+"|", {"Route_Name", "On", "XferOn", "PMT"}, {{"Sort Order", {{"Route_Name", "Ascending"}}}})
    OnTotal = VectorStatistic(Data[2], "Sum", )
    XFRTotal = VectorStatistic(Data[3], "Sum", )
    PMTTotal = VectorStatistic(Data[4], "Sum", )
    
    //Rates
    Data = Data + {Data[3] / (Data[2] - Data[3])}  //Transfer Rate
    Data = Data + {Data[4] / Data[2]}  //PMT per Boarding
    
    for ii = 1 to Data.length do //convert vectors to arrays
        Data[ii] = V2A(Data[ii])
    end
    //Data[1][1]='None'
NextStep = "Get Data by Route Number"
SetStatus(1, NextStep, )

    //Aggregate
    CreateExpression(join_vw, "AggBy", 'if RT_NUMBER = null then (RT_AUTHOR + " " + RT_NAME) else (RT_AUTHOR + " " + RT_NUMBER)', )
    agg_sets = {{"On", "SUM"}, {"XferOn", "SUM"}, {"PMT", "Sum"}, {"RT_AUTHOR", "Dom"}, {"RT_NUMBER", "Dom"}}
    agg2_vw = AggregateTable("AggByNumber", join_vw+"|", "MEM", null, "AggBy", agg_sets, {{"Missing as zero"}})
    
    //Load into Table
    Data2 = GetDataVectors(agg2_vw+"|", {"AggBy", "On", "XferOn", "PMT"}, {{"Sort Order", {{"RT_AUTHOR", "Ascending"}, {"RT_NUMBER", "Ascending"}}}})
    
    //Rates
    Data2 = Data2 + {Data2[3] / (Data2[2] - Data2[3])}  //Transfer Rate
    Data2 = Data2 + {Data2[4] / Data2[2]}  //PMT per Boarding
    
    for ii = 1 to Data2.length do //convert vectors to arrays
        Data2[ii] = V2A(Data2[ii])
    end
    //Data2[1][1]='None'
    CloseView(agg2_vw)
    
NextStep = "Get On-Off Data by Operator"
SetStatus(1, NextStep, )

    agg_sets = {{"On", "SUM"}, {"XferOn", "SUM"}, {"PMT", "SUM"}}
    agg3_vw = AggregateTable("AggByOperator", join_vw+"|", "MEM", null, "RT_AUTHOR", agg_sets, {{"Missing as zero"}})
    
    Data3 = GetDataVectors(agg3_vw+"|", {"RT_AUTHOR", "On", "XferOn", "PMT"}, {{"Sort Order", {{"RT_AUTHOR", "Ascending"}}}})
    
    //Rates
    Data3 = Data3 + {Data3[3] / (Data3[2] - Data3[3])}  //Transfer Rate
    Data3 = Data3 + {Data3[4] / Data3[2]}  //PMT per Boarding
    
    for ii = 1 to Data3.length do //convert vectors to arrays
        Data3[ii] = V2A(Data3[ii])
    end
    //Data3[1][1] = 'None'
    CloseView(agg3_vw)
    
    //Close remaining views
    CloseView(join1_vw)
    CloseView(join_vw)
    CloseView(agg_onoff_vw)
    CloseMap(map)
    
NextStep = "Get Linked Transit Trips"
SetStatus(1, NextStep, )

    //path_ = SplitPath(onoff_file)
    //transit_total_path = path_[1] + path_[2] + '\\transit_total.csv'
    //TripTotal_view = OpenTable('transit_total', "CSV", {transit_total_path},)
    //TripTotal_vector = GetDataVector(TripTotal_view + "|", "transit_total",)
    //TripTotal = TripTotal_vector[1]
    
    Output_dir = Perf.Args.Info.[Output Directory]
    ABMVIZ_Directory = Output_dir + "\\ActivitySim\\visualizer"
    tripmode_county = ABMVIZ_Directory + "/tripmode_county.csv"
    tripmode_countyView = OpenTable("tripmode_county","CSV",{tripmode_county})
    {Trip_All} = GetDataVectors(tripmode_countyView+"|", {"All"},)
    TripTotal = Trip_All[6] +  Trip_All[7] +  Trip_All[8]

NextStep = "Tranform for Table Write"
SetStatus(1, NextStep, )

    //Total Row
    total_row = {{OnTotal, XFRTotal, PMTTotal, XFRTotal/(OnTotal-XFRTotal), PMTTotal/OnTotal}}
    
    //Detailed version
    RowNames = Data[1] + {"Total"}
    TableData = TransposeArray(ExcludeArrayElements(Data, 1, 1))
    TableData = TableData + total_row
    
    //Aggregate version
    RowNames2 = Data2[1] + {"Total"}
    TableData2 = TransposeArray(ExcludeArrayElements(Data2, 1, 1))
    TableData2 = TableData2 + total_row
    
    //Operator version
    RowNames3 = Data3[1] + {"Total"}
    TableData3 = TransposeArray(ExcludeArrayElements(Data3, 1, 1))
    TableData3 = TableData3 + total_row
    
NextStep = "Linked Trip Summaries"
SetStatus(1, NextStep, )
    
    //Add rows with boarding total summaries
    RowNames4 = {"Linked Trips", "Total Boardings", "Boardings per Trip", "Total PMT", "PMT per Linked Trip"}
    dim TableData4[RowNames4.length, 1]
    fmts4 = CopyArray(TableData4)
    
    TableData4[1][1] = TripTotal            fmts4[1][1] = "*,."
    TableData4[2][1] = OnTotal               fmts4[2][1] = "*,."
    TableData4[3][1] = OnTotal/TripTotal     fmts4[3][1] = "*.00"
    TableData4[4][1] = PMTTotal              fmts4[4][1] = "*,."
    TableData4[5][1] = PMTTotal/TripTotal    fmts4[5][1] = "*.00"
    
NextStep = "Write boarding tables"
SetStatus(1, NextStep, )

    //Common formats and column names
    row_fmt = {"*,.", "*,.", "*,.", "*.00", "*.00"}
    col_names = {"Operator", "Boardings", "Transfers", "PMT", "Transfer Rate", "PMT/Boarding"}
    
    Tables = null
    Tables2 = null

    // ==== By Operator Only ====
    dim fmts3[TableData3.length]
    for ii = 1 to fmts3.length do
        fmts3[ii] = row_fmt
    end
    TB = null
    TB.Name = "Transit Boarding Summary by Operator"
    TB.Section1 = "By Operator"
    TB.Footnote = "*Transfers include transfers from other operators"
    TB.Table.TableData = TableData3
    TB.Table.RowNames = RowNames3
    TB.Table.ColNames = col_names
    TB.Table.Formats = fmts3
    TB.Table.Class = "dataframe no-last-col"
    
    Tables = Tables + {CopyArray(TB)}
    
    //General Report
    TB.Section1 = null
    Tables2 = Tables2 + {CopyArray(TB)}
    
    //Add a boardings chart
    CH = null
    CH.Name = "Transit Boardings by Operator"
    CH.Section1 = "By Operator"
    CH.Chart.CanvasID = "transit_boardings_chart_operator"
    CH.Chart.Type = 'bar'
    CH.Chart.Labels = Data3[1]
    //SEMCOG requested moving PMT to another chart.  Leaving commented code in case someone wants it added back.
    //CH.Chart.Data = {Round(A2V(Data3[2]), 0), Round(A2V(Data3[3]), 0)}
    //CH.Chart.Names = {"Boardings", "PMT"}
    CH.Chart.Data = {Round(A2V(Data3[2]), 0)}
    CH.Chart.Names = {"Boardings"}
    CH.Chart.XAxis = "Route"
    CH.Chart.YAxis = "Daily Boardings"
    
    Tables = Tables + {CopyArray(CH)}
    
    //General Report
    CH.Section1 = null
    Tables2 = Tables2 + {CopyArray(CH)}
    
    //Add a separate PMT Chart
    CH = null
    CH.Name = "Transit PMT by Operator"
    CH.Section1 = "By Operator"
    CH.Chart.CanvasID = "transit_pmt_chart_operator"
    CH.Chart.Type = 'bar'
    CH.Chart.Labels = Data3[1]
    CH.Chart.Data = {Round(A2V(Data3[3]), 0)}
    //CH.Chart.Colors = {{237, 125, 49}, {255, 192, 0}, {68, 114, 196}, {112, 173, 71}, {91, 155, 213}}
    CH.Chart.Colors = Subarray(Perf.chartDefaults.Colors, 2, ) //start with color #2
    CH.Chart.Names = {"PMT"}
    CH.Chart.XAxis = "Route"
    CH.Chart.YAxis = "Daily PMT"
    
    Tables = Tables + {CopyArray(CH)}
    
    //General Report
    CH.Section1 = null
    Tables2 = Tables2 + {CopyArray(CH)}
    
    // ==== Linked Trip Summary Table ====
   
    TB = null
    TB.Name = "Linked Trip Summary"
    TB.Section1 = "By Operator"
    TB.Table.TableData = TableData4
    TB.Table.RowNames = RowNames4
    TB.Table.ColNames = {"Statistic", "Value"}
    TB.Table.Formats = fmts4
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}
    
    //General Report
    TB.Section1 = null
    Tables2 = Tables2 + {CopyArray(TB)}
    
    

    // ==== By Operator and Route ====
    dim fmts2[TableData2.length]
    for ii = 1 to fmts2.length do
        fmts2[ii] = row_fmt
    end

    TB = null
    TB.Name = "Transit Boarding Summary by Operator and Number"
    TB.Section1 = "By Route"
    TB.Table.TableData = TableData2
    TB.Table.RowNames = RowNames2
    TB.Table.ColNames = col_names
    TB.Table.Formats = fmts2
    TB.Table.Class = "dataframe no-last-col"
    
    Tables = Tables + {TB}
    
    //Add a boardings chart
    CH = null
    CH.Name = "Transit Boardings by Operator and Number"
    CH.Section1 = "By Route"
    CH.Chart.CanvasID = "transit_boardings_chart_agg"
    CH.Chart.Type = 'bar'
    CH.Chart.Labels = Data2[1]
    CH.Chart.Data = {Round(A2V(Data2[2]), 0)}
    CH.Chart.Names = {"Boardings"}
    CH.Chart.XAxis = "Route"
    CH.Chart.YAxis = "Daily Boardings"
    
    
    Tables = Tables + {CH}


    // ==== Detailed Version ====
    
    dim fmts[TableData.length]
    for ii = 1 to fmts.length do
        fmts[ii] = row_fmt
    end

    TB = null
    TB.Section1 = "By Route"
    TB.Section2 = "Additional Details"
    TB.Name = "Transit Boardings by Route"
    TB.Table.TableData = TableData
    TB.Table.RowNames = RowNames
    TB.Table.ColNames = col_names
    TB.Table.Formats = fmts
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {TB}
    
    //Add a boardings chart
    CH = null
    CH.Section1 = "By Route"
    CH.Section2 = "Additional Details"
    CH.Name = "Transit Boarding Chart by Route"
    CH.Chart.CanvasID = "transit_boardings_chart"
    CH.Chart.Type = 'bar'
    CH.Chart.Labels = Data[1]
    CH.Chart.Data = {Round(A2V(Data[2]), 0)}
    CH.Chart.Names = {"Boardings"}
    CH.Chart.XAxis = "Route"
    CH.Chart.YAxis = "Daily Boardings"
    
    
    Tables = Tables + {CH}
	
    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables2)
    
    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)
	
	SetStatus(1, "@System0", )
    Return(True)
EndMacro //End of Transit Assignment Summary

// ****************************************************************************************************************
// ABM Summary
//
Macro "RPT ASIM Summary Report" (Perf)

    Input_dir = Perf.Args.Info.[Input Directory]
    Output_dir = Perf.Args.Info.[Output Directory]
    scen_name = Perf.Args.Info.Name
    ABMVIZ_Directory = Output_dir + "\\ActivitySim\\visualizer"
    EXTAirportFolder = Output_dir + "\\EXTAirport"

    TotalsFile = ABMVIZ_Directory  +"\\totals.csv"
    ToursByPurposeFile = ABMVIZ_Directory + "\\tours_purpose_type.csv"
    ToursByPurposeAndModeFile = ABMVIZ_Directory + "\\tmodeProfile_vis.csv"
    TripsByPurposeAndModeFile = ABMVIZ_Directory + "\\tripModeProfile_vis.csv"

    tour_county = ABMVIZ_Directory + "/tours_county.csv"
    trip_county = ABMVIZ_Directory + "/trips_county.csv"
    tripmode_county = ABMVIZ_Directory + "/tripmode_county.csv"
    toursmode_income = ABMVIZ_Directory + "/toursmode_income.csv"
    toursmode_auto = ABMVIZ_Directory + "/tourmode_auto.csv"
    extairport_county = ABMVIZ_Directory + "/extairport_county.csv"
 

    //SED = Input_dir + "\\Zonal_Data"
    Airport_pa = EXTAirportFolder + "\\PA_AIRPORT.mtx"
    EI_pa = EXTAirportFolder + "\\PA_EI.mtx"
    IE_pa = EXTAirportFolder + "\\PA_IE.mtx"
    EE = Perf.Args.[External External file]

    land_use = Perf.Args.[Land Use Data]
    
    //////
    tour_countyView = OpenTable("tour_county","CSV",{tour_county})
    
    {variable, Detroit, Wayne, Oakland, Macomb, Washtenaw, Monroe, StClair, Livingston, All} = GetDataVectors(tour_countyView+"|", {"primary_purpose","Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"},)

    RowNames1 = variable
    dim TableData1[RowNames1.length, 9]
    fmts1 = CopyArray(TableData1)

    for i=1 to RowNames1.length do
        for j=1 to 9 do
            fmts1[i][j] = "*,."
        end
    end
    for i=1 to RowNames1.length do
        TableData1[i][1] = Detroit[i]
    end
    for i=1 to RowNames1.length do
        TableData1[i][2] = Wayne[i]
    end
    for i=1 to RowNames1.length do
        TableData1[i][3] = Oakland[i]
    end
    for i=1 to RowNames1.length do
        TableData1[i][4] = Macomb[i]
    end
    for i=1 to RowNames1.length do
        TableData1[i][5] = Washtenaw[i]
    end
    for i=1 to RowNames1.length do
        TableData1[i][6] = Monroe[i]
    end
    for i=1 to RowNames1.length do
        TableData1[i][7] = StClair[i]
    end
    for i=1 to RowNames1.length do
        TableData1[i][8] = Livingston[i]
    end
    for i=1 to RowNames1.length do
        TableData1[i][9] = All[i]
    end
    ///
    trips_countyView = OpenTable("trips_county","CSV",{trip_county})
    
    {variable, Detroit, Wayne, Oakland, Macomb, Washtenaw, Monroe, StClair, Livingston, All} = GetDataVectors(trips_countyView+"|", {"primary_purpose","Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"},)

    RowNames2 = variable
    dim TableData2[RowNames2.length, 9]
    fmts2 = CopyArray(TableData2)

    for i=1 to RowNames2.length do
        for j=1 to 9 do
            fmts2[i][j] = "*,."
        end
    end
    for i=1 to RowNames2.length do
        TableData2[i][1] = Detroit[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][2] = Wayne[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][3] = Oakland[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][4] = Macomb[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][5] = Washtenaw[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][6] = Monroe[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][7] = StClair[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][8] = Livingston[i]
    end
    for i=1 to RowNames2.length do
        TableData2[i][9] = All[i]
    end
    //////
    tripmode_countyView = OpenTable("tripmode_county","CSV",{tripmode_county})
    
    {variable, Detroit, Wayne, Oakland, Macomb, Washtenaw, Monroe, StClair, Livingston, All} = GetDataVectors(tripmode_countyView+"|", {"tripmode_recode","Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"},)

    RowNames3 = variable
    dim TableData3[RowNames3.length, 9]
    fmts3 = CopyArray(TableData3)

    for i=1 to RowNames3.length do
        for j=1 to 9 do
            fmts3[i][j] = "*,."
        end
    end
    for i=1 to RowNames3.length do
        TableData3[i][1] = Detroit[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][2] = Wayne[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][3] = Oakland[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][4] = Macomb[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][5] = Washtenaw[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][6] = Monroe[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][7] = StClair[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][8] = Livingston[i]
    end
    for i=1 to RowNames3.length do
        TableData3[i][9] = All[i]
    end

    ///
    ToursByPurpModeView = OpenTable("ToursByPurposeAndMode","CSV",{ToursByPurposeAndModeFile})
    SetView(ToursByPurpModeView)
 
    //note that the field names are messed up because there is no header for purpose number. duh.
    {id,purpose,freq_as0,freq_as1,freq_as2,freq_all} = GetDataVectors(ToursByPurpModeView+"|", {"id","purpose","freq_as0","freq_as1","freq_as2","freq_all"},{{"Sort Order",{{"id","Ascending"}}},{"Missing as Zero", "True"}})
    

    Modes= {"Drive alone", "Shared 2", "Shared 3+", "Walk", "Bike", "Walk-Transit", "PNR-Transit", "KNR-Transit","School bus", "Ride-hail"}
    Purp = {"work", "univ", "sch","imain","idisc","jmain","jdisc","atwork","Total"}
    
    //reformat input vectors to 2-d array
    dim modepurp[Modes.length,Purp.length]
    dim totalsByPurp[Purp.length]
    for i=1 to Purp.length do
        totalsByPurp[i] =0
    end
    for row = 1 to id.length do
        purpIndex = RunMacro("Find String In Array",purpose[row],Purp)
        modepurp[S2I(id[row])][purpIndex] = freq_all[row]
        totalsByPurp[purpIndex] = totalsByPurp[purpIndex] + freq_all[row]
    end

    dim TableData4[Purp.length, Modes.length+1]
    fmts4 = CopyArray(TableData4)

    for i=1 to modepurp.length do
        for j=1 to modepurp[1].length do
            TableData4[j][i] = modepurp[i][j]
            fmts4[j][i] = "*,."
        end
    end
    for i=1 to totalsByPurp.length do
        TableData4[i][Modes.length+1] = totalsByPurp[i]
        fmts4[i][Modes.length+1] = "*,."
    end

    ///
    toursmode_incomeView = OpenTable("toursmode_income","CSV",{toursmode_income})
    
    {variable, DA, S2, S3, WLK, BIKE, WTR, PNRTR, KNRTR, SCH, TAXI, All} = GetDataVectors(toursmode_incomeView+"|", {"income_segment","DRIVEALONE", "SHARED2", "SHARED3", "WALK", "BIKE", "Local Transit", "PRM Transit", "MIX Transit","SCHOOLBUS", "TAXI/RIDEHAIL", "All"},)

    RowNames5 = variable
    dim TableData5[RowNames5.length, 11]
    fmts5 = CopyArray(TableData5)

    for i=1 to RowNames5.length do
        for j=1 to 11 do
            fmts5[i][j] = "*,."
        end
    end
    for i=1 to RowNames5.length do
        TableData5[i][1] = DA[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][2] = S2[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][3] = S3[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][4] = WLK[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][5] = BIKE[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][6] = WTR[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][7] = PNRTR[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][8] = KNRTR[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][9] = SCH[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][10] = TAXI[i]
    end
    for i=1 to RowNames5.length do
        TableData5[i][11] = All[i]
    end
    ///

    toursmode_autoView = OpenTable("toursmode_auto","CSV",{toursmode_auto})
    
    {variable, DA, S2, S3, WLK, BIKE, WTR, PNRTR, KNRTR, SCH, TAXI, All} = GetDataVectors(toursmode_autoView+"|", {"auto_recode","DRIVEALONE", "SHARED2", "SHARED3", "WALK", "BIKE", "Local Transit", "PRM Transit", "MIX Transit","SCHOOLBUS", "TAXI/RIDEHAIL", "All"},)

    RowNames6 = variable
    dim TableData6[RowNames6.length, 11]
    fmts6 = CopyArray(TableData6)

    for i=1 to RowNames6.length do
        for j=1 to 11 do
            fmts6[i][j] = "*,."
        end
    end
    for i=1 to RowNames6.length do
        TableData6[i][1] = DA[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][2] = S2[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][3] = S3[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][4] = WLK[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][5] = BIKE[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][6] = WTR[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][7] = PNRTR[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][8] = KNRTR[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][9] = SCH[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][10] = TAXI[i]
    end
    for i=1 to RowNames6.length do
        TableData6[i][11] = All[i]
    end
    ///

    TripsByPurpModeView = OpenTable("ToursByPurposeAndMode","CSV",{TripsByPurposeAndModeFile})
    SetView(TripsByPurpModeView)
 
    //note that the field names are messed up because there is no header for purpose number. duh.
    {tripmode,tourmode,purpose,value} = GetDataVectors(TripsByPurpModeView+"|", {"tripmode", "tourmode", "grp_var","value"},{{"Sort Order",{{"tripmode","Ascending"}}},{"Missing as Zero", "True"}})
    
    //Todo: Check modes!
    Modes= {"Drive alone", "Shared 2", "Shared 3+", "Walk", "Bike", "Walk-Transit", "PNR-Transit", "KNR-Transit","School bus", "Ride-hail"}
    Purp = {"workTotal", "univTotal", "schlTotal","imainTotal","idiscTotal","jmainTotal","jdiscTotal","atworkTotal", "totalTotal"}
    
    //reformat input vectors to 2-d array
    dim modepurp[Modes.length,Purp.length]
    dim totalsByPurp[Purp.length]
    for i=1 to Purp.length do
        totalsByPurp[i] =0
    end
    for row = 1 to tripmode.length do
        px = right(purpose[row], 5)
        if purpose[row] contains "Total" then do
            p = purpose[row]
            purpIndex = RunMacro("Find String In Array",p,Purp)
            idx = S2I(tripmode[row])
            modepurp[idx][purpIndex] = value[row]
            totalsByPurp[purpIndex] = totalsByPurp[purpIndex] + value[row]
        end
    end

    dim TableData7[Purp.length, Modes.length+1]
    fmts7 = CopyArray(TableData7)

    for i=1 to modepurp.length do
        for j=1 to modepurp[1].length do
            TableData7[j][i] = modepurp[i][j]
            fmts7[j][i] = "*,."
        end
    end

    for i=1 to totalsByPurp.length do
        TableData7[i][Modes.length+1] = totalsByPurp[i]
        fmts7[i][Modes.length+1] = "*,."
    end

    ///
    extairport_countyView = OpenTable("extairport_county","CSV",{extairport_county})
    
    {Detroit, Wayne, Oakland, Macomb, Washtenaw, Monroe, StClair, Livingston, All} = GetDataVectors(extairport_countyView+"|", {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"},)

    RowNames8 = {"External Passenger Trips To", "External Passenger Trips From", "DTW Passenger Trips To", "DTW Passenger Trips From", "External-External Passenger Trips"}
    dim TableData8[RowNames8.length, 9]
    fmts8 = CopyArray(TableData8)

    for i=1 to RowNames8.length do
        for j=1 to 9 do
            fmts8[i][j] = "*,."
        end
    end
    for i=1 to RowNames8.length do
        TableData8[i][1] = Detroit[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][2] = Wayne[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][3] = Oakland[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][4] = Macomb[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][5] = Washtenaw[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][6] = Monroe[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][7] = StClair[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][8] = Livingston[i]
    end
    for i=1 to RowNames8.length do
        TableData8[i][9] = All[i]
    end



    // airport_pa = OpenMatrix(Airport_pa, "Trips")
    // stat_array = MatrixStatistics(airport_pa, )
    // total_airport = stat_array.Trips.Sum

    // ei_pa = OpenMatrix(EI_pa, "Trips")
    // stat_array = MatrixStatistics(ei_pa, )
    // total_ei = stat_array.Trips.Sum
    // ie_pa = OpenMatrix(IE_pa, "Trips")
    // stat_array = MatrixStatistics(ie_pa, )
    // total_ie = stat_array.Trips.Sum
    // EE = OpenTable("EE","CSV",{EE})
    // SetView(EE)
    // {sov_ee,hov2_ee,hov3_ee} = GetDataVectors(EE+"|", {"SOV","HOV2","HOV3"},)
    // total_ee = VectorStatistic(sov_ee, "Sum", ) +  VectorStatistic(hov2_ee, "Sum", ) +  VectorStatistic(hov3_ee, "Sum", )

    // total_external = total_ei + total_ie + total_ee

    // RowNames5 = {"Total airport trips", "Total internal-external trips", "Total external-internal trips", "Total external-external trips"}
    // dim TableData5[RowNames5.length, 1]
    // fmts5 = CopyArray(TableData5)
    
    // TableData5[1][1] = total_airport               fmts5[1][1] = "*,."
    // TableData5[2][1] = total_ie                    fmts5[2][1] = "*,."
    // TableData5[3][1] = total_ei                    fmts5[1][1] = "*,."
    // TableData5[4][1] = total_ee                    fmts5[2][1] = "*,."

    //

    
NextStep = "Write summary"
SetStatus(1, NextStep, )

    TB = null
    TB.Name = "Tour Count by Primary Purpose"
    TB.Section1 = "Person Travel Totals by Resident County"
    TB.Table.TableData = TableData1
    TB.Table.RowNames = {'At-work', 'Eat-out', 'Escort', 'Other Discretionary', 'Other Maintenance',
       'School', 'Shopping', 'Social', 'University', 'Work', 'Total'}
    TB.Table.ColNames = {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "St. Clair", "Livingston", "All"}
    TB.Table.Formats = fmts1
    TB.Table.Class = "dataframe no-last-any"
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Trip Count by Primary Purpose"
    TB.Section1 = "Person Travel Totals by Resident County"
    TB.Table.TableData = TableData2
    TB.Table.RowNames = {'At-work', 'Eat-out', 'Escort', 'Other Discretionary', 'Other Maintenance',
       'School', 'Shopping', 'Social', 'University', 'Work', 'Total'}
    TB.Table.ColNames = {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "St. Clair", "Livingston", "All"}
    TB.Table.Formats = fmts2
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Trip Count by Trip Mode"
    TB.Section1 = "Person Travel Totals by Resident County"
    TB.Table.TableData = TableData3
    TB.Table.RowNames = {"Drive alone", "Shared 2", "Shared 3+", "Walk", "Bike", "Local Transit", "PRM Transit", "MIX Transit","School bus", "Ride-hail", 'Total'}
    TB.Table.ColNames = {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "St. Clair", "Livingston", "All"}
    TB.Table.Formats = fmts2
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}  

    B = null
    TB.Name = "Tour Mode Choice by Purpose"
    TB.Section1 = "Person Travel Mode Chocie"
    TB.Table.TableData = TableData4
    TB.Table.RowNames = {"Work", "University", "School","Individual Maintenance","Individual Discretionary","Joint Maintenance","Joint Discretionary","At-work","Total"}
    TB.Table.ColNames = {"Purpose", "Drive alone", "Shared 2", "Shared 3+", "Walk", "Bike", "Walk-Transit", "PNR-Transit", "KNR-Transit","School bus", "Ride-hail", "Total"}
    TB.Table.Formats = fmts4
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    B = null
    TB.Name = "Tour Mode Choice by HH Income"
    TB.Section1 = "Person Travel Mode Chocie"
    TB.Table.TableData = TableData5
    TB.Table.RowNames = {'Low Income', 'Low-Med Income', 'Med-High Income', 'High Income', 'Total'}
    TB.Table.ColNames = {"Income Segment", "Drive alone", "Shared 2", "Shared 3+", "Walk", "Bike", "Local Transit", "PRM Transit", "MIX Transit", "School bus", "Ride-hail", "Total"}
    TB.Table.Formats = fmts5
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    B = null
    TB.Name = "Tour Mode Choice by Auto Sufficiency "
    TB.Section1 = "Person Travel Mode Chocie"
    TB.Table.TableData = TableData6
    TB.Table.RowNames = {'Zero-Auto HHs', 'Auto < Workers', 'Auto = Workers', 'Auto > Workers', 'Total'}
    TB.Table.ColNames = {"Auto Sufficiency","Drive alone", "Shared 2", "Shared 3+", "Walk", "Bike", "Local Transit", "PRM Transit", "MIX Transit","School bus", "Ride-hail", "Total"}
    TB.Table.Formats = fmts6
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}


    B = null
    TB.Name = "Trip Mode Choice by Purpose"
    TB.Section1 = "Person Travel Mode Chocie"
    TB.Table.TableData = TableData7
    TB.Table.RowNames = {"Work", "University", "School","Individual Maintenance","Individual Discretionary","Joint Maintenance","Joint Discretionary","At-work","Total"}
    TB.Table.ColNames = {"Purpose", "Drive alone", "Shared 2", "Shared 3+", "Walk", "Bike", "Walk-Transit", "PNR-Transit", "KNR-Transit","School bus", "Ride-hail", "Total"}
    TB.Table.Formats = fmts7
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    TB = null
    TB.Name = "Total Airport and Passenger External Trips"
    TB.Section1 = "Airport and External Model Summaries"
    TB.Table.TableData = TableData8
    TB.Table.RowNames = RowNames8
    TB.Table.ColNames = {"Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "St. Clair", "Livingston", "Total"}
    TB.Table.Formats = fmts8
    TB.Table.Class = "dataframe no-last-any"
    
    Tables = Tables + {CopyArray(TB)}

    Perf.fp = Perf.fp2
    Perf.WriteTables(Tables, ) //General

    Perf.fp = Perf.fp1
    Perf.WriteTables(Tables)

    Return(True)
EndMacro //End of Transit Assignment Summary

Macro "Find String In Array"(key, array)

  for i = 1 to array.length do
        ret = CompareStrings(key,array[i],)
		if(ret="True") then do
		   return(i)
		end
	end
	
	return(0)
EndMacro	



// ****************************************************************************************************************
Class "Utilities" //StartClass

    //**************************************************************************
    //** Returns a nicely formatted date and time
	Macro "FormatDate" (daytime) do
    //** Optional string daytime = Day/Time formatted as returned by 
    //**                           GetDateAndTime(). Uses the current date/time
    //**                           if ommitted.
    //**
    //** Returns --> String RetVal = Formatted date and time
    //**************************************************************************

		if daytime = null then daytime = GetDateAndTime()
		
		date_arr = ParseString(daytime, " ")
		day = date_arr[1]
		mth = date_arr[2]
		num = date_arr[3]
		time = date_arr[4]
		time_arr = ParseString(time, ":")
		year = date_arr[5]

		//Define day strings
		Days.Sun = "Sunday"
		Days.Mon = "Monday"
		Days.Tue = "Tuesday"
		Days.Wed = "Wednesday"
		Days.Thu = "Thursday"
		Days.Fri = "Friday"
		Days.Sat = "Saturday"

		//Define month strings
		Months.Jan = "January"
		Months.Feb = "February"
		Months.Mar = "March"
		Months.Apr = "April"
		Months.May = "May"
		Months.Jun = "June"
		Months.Jul = "July"
		Months.Aug = "August"
		Months.Sep = "September"
		Months.Oct = "October"
		Months.Nov = "November"
		Months.Dec = "December"

    	//Format the date string
    	if      s2i(time_arr[1]) = 0 then  RetVal = Days.(day) + ", " + 
                                                    Months.(mth) + " " + 
                                                    num + ", " + 
                                                    year + 
                                                    " (" + "12" + ":" + 
                                                    time_arr[2] + " AM)"
		else if s2i(time_arr[1]) < 12 then RetVal = Days.(day) + ", " + 
                                                    Months.(mth) + " " + 
                                                    num + ", " + 
                                                    year + " (" + 
                                                    time_arr[1] + 
                                                    ":" + time_arr[2] + " AM)"
		else if s2i(time_arr[1]) = 12 then RetVal = Days.(day) + ", " + 
                                                    Months.(mth) + " " + 
                                                    num + ", " + 
                                                    year + " (" + 
                                                    time_arr[1] + 
                                                    ":" + time_arr[2] + " PM)"
		else RetVal = Days.(day) + ", " + Months.(mth) + " " + num + ", " + 
                      year + " (" + i2s(s2i(time_arr[1])-12) + ":" + 
                      time_arr[2] + " PM)"

		//Return
		Return(RetVal)
	//EndMethod
	EndItem
    
    //**************************************************************************
    //** Return a list of keys in an array of {key, value} pairs.
    Macro "Keys" (var) do
    //** Opts array var = key/value pairs
    //**
    //** Returns --> Array r = list of keys
    //**************************************************************************
    
        if TypeOf(var) != 'array' then do
            Throw("Invalid argument passed to UT.Keys")
        end

        dim r[var.length]
        for i = 1 to var.length do
            r[i] = var[i][1]
        end
        
        var = null
        Return(r)
        
    //EndMethod
    EndItem
    
    //**************************************************************************
    //** Return a list of values in an array of {key, value} pairs.
    Macro "Values" (var) do
    //** Opts array var = key/value pairs
    //**
    //** Returns --> Array r = list of values
    //**************************************************************************
    
        if TypeOf(var) != 'array' then do
            Throw("Invalid argument passed to UT.Values")
        end

        dim r[var.length]
        for i = 1 to var.length do
            r[i] = var[i][2]
        end
        
        var = null
        Return(r)
        
    //EndMethod
    EndItem

EndClass