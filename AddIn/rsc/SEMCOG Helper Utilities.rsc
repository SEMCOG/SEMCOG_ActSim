Macro "TestMe"

    shared Scen
    Scen = null
    
    Scen.ExpandSettings.PER_TRN2 = {"AM", "MD"} //2-period transit periods
    Scen.ExpandSettings.TMODE = {"LOC", "PRM", "MIX"}
    Scen.ExpandSettings.AMODE  = {"WLK", "DRV"}
    
    template = 'TSkm\%PER_TRN2%_%AMODE%_%TMODE%_Skim.mtx'
    
    UT = null
    UT = CreateObject("Utilities")
    
    Opts = null
    Opts.NestOrder = {"PER_TRN2", "AMODE"} //, "TMODE"}
    
    tv = UT.Expand(template, Opts)
    
    ShowArray(tv)

EndMacro

//******************************************************************************
//**                                                                          **
//**               Travel Model Helper Utility Functions                      **
//**                                                                          **
//**          The Utilities object contains general-purpose                   **
//**   utilities useful in the implementation of travel models in TransCAD.   **
//**                                                                          **
//**                     Designed for TransCAD 7.0                            **
//**                                                                          **
//**                                                                          **
//**                                                                          **
//** ------------------------------------------------------------------------ **
//** Search for the string 'Class "' to locate the start of each object       **
//**                                                                          **
//** File Contents:                                                           **
//**  - Utilities: General purpose utilities                                  **
//**  - TransitUT: Route System/Transit Utilities                             **
//**                                                                          **
//******************************************************************************


//******************************************************************************
//** Utilities: General use utilities, including table management, matrix     **
//**            management,  File/directory dialogs, and some Misc. tools     **
Class "Utilities"                                                           //**
//StartClass
//**                                                                          **
//** Contents:                                                                **
//**  CreateOutputDirs: Creates output directories required for a model step  **
//**  Delete: Deletes a file, table, or geographic file                       **
//**  -- Table/View management --                                             **
//**  AddViewFields: Add fields to a view                                     **
//**  DropViewFields: Drops fields from a view                                **
//**  RenameViewFields: Renames fields in a view                              **
//**  -- Matrix management --                                                 **
//**  DeleteMtxIndex: Deletes a matrix index (failsafe)                       **
//**  AddMtxCore: Adds a matrix core (failsafe)                               **
//**  MatLbl: Return matrix filename and label                                **
//**  IEIncices: Create Internal and External matrix indices                  **
//**  SubareaIndices: Create matrix indices referring to subareas             **
//**  TAZIndex: Replace ID indices with TAZ indices in a matrix               **
//**  OpenMatrixMem: Open a matrix by copying to a memory only matrix         **
//**  MatrixTotal: Returns the total from a matrix currency                   **
//**  -- File/Directory dialogs --                                            **
//**  GetSaveAs: Gets a Save As filename from the user                        **
//**  GetOpen: Gets an Open filename from the user                            **
//**  ChooseDir: Gets a directory name from the user                          **
//**  -- Layer Management --                                                  **
//**  RouteSystemMap: Opens a route system in a new map                       **
//**  -- Misc. Factory functions --                                           **
//**  FormatDate: Converts the data and time into a nice format               **
//**  FormatTime: Converts seconds of time into hr:min:sec                    **
//**  KillBars: Kills any left-over progress bars                             **
//**  Keys: Returns a list of keys in an array of name/value pairs            **
//**  Values: Returns a list of values in an array of name/value pairs        **
//**  TableType: Returns the type of a table for OpenTable                    **
//**  SelectList: Returns a list of the select query names in a .qry file     **
//**  NetworkSetting: Sets up network FT/Node styles and saves settings		  **
//**  SkimCheck: Checks a skim matrix for un-connected zones                  **
//**  QuickTag: Replacement tag function that is quicker in some cases        **
//**  CalcLinkAT: Calculate link area type based on TAZ area type             **
//**  Expand: Expand filename based on template                               **
//**  ShowValue: Shows an integer, real, string, null, array, Opts, etc.      **
//**  TreeOpt: Create a tree variable to display an Opts array                **
//**  IsOpt: Returns True/False indicating if an array is an options array    **
//**  OutputRTS: Returns an output rts file name/path                         **
//**  ReadParams: Read parameters from a BIN file into an Opts array          **
//**  ClearDir: Clear a directory, create if it doesn't exist                 **
//**  Fratar: Run an iterative proportional factoring routine                 **
//**  SpinnerList: Create a list for a dbox spinner                           **
//**  AttachCounts: Attach a count view to the network                        **
//**                                                                          **
//******************************************************************************


    //**************************************************************************
    //** Create all output directories for an option-style list of files
	Macro "CreateOutputDirs" (Opts) do
    //** Checks a list of complete filepaths and creates directories for 
    //** to non-existent directories
    //**
    //** Array Opts = Options array of Key/Filepath pairs
    //**             .Key = string CompleteFilePath
    //**************************************************************************
	
		//Get a list of directories that need to be created
		req_dirs = null
		for i = 1 to Opts.length do
			file = Opts.(Opts[i][1]).Value  //Each file in the options array
			dir = SplitPath(file)
			dir = dir[1]+dir[2]
			
			//If this directory is not already in the list
			if ArrayPosition(req_dirs, {dir}, ) = 0 then do
				req_dirs = req_dirs + {dir}
			end
		end
		
		//Create each directory in the list
		for i = 1 to req_dirs.length do
		
			//Get all parent directory info
			tmp = SplitPath(req_dirs[i])
			drive = tmp[1]
			dir_parts = ParseString(tmp[2], "\\")
			
			cur_dir = tmp[1]  //e.g., "C:\\"
			if right(cur_dir, 1) <> "\\" then cur_dir = cur_dir + "\\"
			for j = 1 to dir_parts.length do
				cur_dir = cur_dir + dir_parts[j]  //no trailing backslash! (yet)
				if GetDirectoryInfo(cur_dir, "Directory") = null then do //GetDirectoryInfo works only w/o a trailing backslash
					CreateDirectory(cur_dir)
				end
				cur_dir = cur_dir + "\\"
			end
		end
	//EndMethod
    EndItem

    //**************************************************************************
    //** Add a set of new fields to an open view
	Macro "AddViewFields" (NewFlds, View, AfterField) do
    //** Add new fields to a table, don't add a duplicate if it already exists.
    //** This is similar to the "TCB Add View Fields" macro, but behaves a bit
    //** differently.
    //** 
    //** Array NewFlds = {{string FieldName, 
    //**                   string Integer/Real/Short/Tiny/Float, 
    //**                   [integer width = 9], 
    //**                   [integer decimals = 2]}, 
    //**                  {...}}
    //**              --> [width] and [decimals] are optional integers with 
    //**                  defaults as shown.  
    //** String View = Name of an open, writable view
    //** Optional String AfterField = Field after which to add new fields. 
    //**                              preexisting fields will not be moved. If 
    //**                              null, fields will be added to the end of 
    //**                              the table
    //**************************************************************************
    
		//Setup
		str = GetTableStructure(View)  //Load existing table structure
		dim already[NewFlds.length]    //Already in the table?

		//Process existing fields
		for i = 1 to str.length do
			//Check for existing field - flag if "add" field already exists
			for j = 1 to NewFlds.length do
				if str[i][1] = NewFlds[j][1] then already[j] = 1
			end
			//Set new field name to original field name on existing fields (retain existing data)
			str[i] = str[i]+{str[i][1]}
		end

		//Prepare the fields to add - only add fields that do not already exist
		modify = null
		new_str = null
		for i = 1 to NewFlds.length do
			if already[i] <> 1 then do
				w = null
				d = null
				if NewFlds[i].length >= 3 then w = NewFlds[i][3]
				if NewFlds[i].length >= 4 then	d = NewFlds[i][4]
				if w = null then w = 9
				if d = null then d = 2
				new_str = new_str + {{NewFlds[i][1], NewFlds[i][2], w, d, "False",,,,,,}}
				modify = 1
			end
		end
		
		//Add the missing fields to the str array
		if AfterField = null then  //If no AfterField was specified, add to the end
			mod_str = str + new_str
		else do
			FieldPos = null
			for i = 1 to str.length do
				if str[i][1] = AfterField then
					FieldPos = i
			end
			if FieldPos = null then //If the field was not found, add to the end
				mod_str = str + new_str
			else  //If the field is found add new fields immediately following
				mod_str = SubArray(str, null, FieldPos) + new_str + SubArray(str, FieldPos+1, )
		end

		if modify = 1 then ModifyTable(View, mod_str)
		Return(1)

	//EndMethod
	EndItem

    //**************************************************************************
    //** Removes fields from table, don't fail if a field doesn't exist
	Macro "DropViewFields" (Flds, View) do
    //** Array Flds = List of field names to drop
    //** String View = String Name of an open, writable view
    //**************************************************************************

    	//Setup and data gathering
    	str = GetTableStructure(View)
    	dim already[str.Length]

    	//For each field:
    	for i = 1 to str.length do
        	//Check for existing field
        	for j = 1 to Flds.length do
            	if str[i][1] = Flds[j] then already[i] = 1
				modify = 1
        	end
    	end

		//Keep only non-deleted fields
		str2 = null
		for i = 1 to already.Length do
			if already[i] <> 1 then do
        		str[i] = str[i]+{str[i][1]}  	//Set new field name to original field name
				str2 = str2 + {str[i]}
			end
		end
    	if modify = 1 then ModifyTable(View, str2)

    	Return(1)

	//EndMethod
	EndItem

    //**************************************************************************
    //** Rename fields without changing any data or data types
	Macro "RenameViewFields" (FieldNames, View) do
    //** Array FieldNames = {{"Old Name", "New Name"}, 
    //**                     {"Old Name 2", "New Name 2"}, 
    //**                     {...}}
    //** String View = Name of an open, writable view
    //**************************************************************************

    	//Setup and data gathering
    	str = GetTableStructure(View)

		for i = 1 to str.length do
			//Add an element to the end of the array, indicating that original data should be used
			str[i] = str[i] + {str[i][1]}
			//Change the name of the field if necessary
			for j = 1 to FieldNames.length do
                //Field names in TC are not case sensitive, so comapre as such
				if Lower(FieldNames[j][1]) = Lower(str[i][1]) then 
					str[i][1] = FieldNames[j][2]
			end
		end

    	ModifyTable(View, str)
    	Return(1)

	//EndMethod
	EndItem

    //**************************************************************************
    //** Creates a DSN file that can be used to read/write Access data
	Macro "CreateDSN" (Filename) do
    //** Creates a DSN file in the TransCAD temporary directory and returns the 
    //** name of the file. Re-using DSN files can result in incorrect management 
    //** of database access, so a new temp DSN file is created each time this 
    //** macro is run.
    //**
    //** String Filename = Complete path to an Access database file
    //**
    //** Returns -> String dsn_file: Complete path to temporary DSN file
    //**************************************************************************

		dsn_file = GetTempFilename(".dsn")
		
        //Check for 64-bit version of TransCAD
        p = GetProgram()
        if p.Length >= 7 and p[7] = 64 then 
            dsn_driver = "DRIVER=Microsoft Access Driver (*.mdb, *.accdb)"
        else
            dsn_driver = "DRIVER=Microsoft Access Driver (*.mdb)"

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
        
	//EndMethod
	EndItem

    //**************************************************************************
    // Open an Access table and store it in a temporary ".bin" file
	Macro "OpenDSN" (dsn_name, tname, index, target_file) do
    //** String dsn_name = DSN filename created by CreateDSN
    //** String tname = Name of the Access table or query
    //** Optional string index = Unique index field
    //** Optional string target_file = Name of .bin file to recieve copy of 
    //**                               the Access table. A passed filename 
    //**                               must include the .bin extension. If 
    //**                               target_file is not specified, this macro 
    //**                               saves the table in a temp file that will 
    //**                               be deleted when the TransCAD program is 
    //**                               next closed. The temp filename is not 
    //**                               returned from this macro.  The temp 
    //**                               filename can be identified by passing a 
    //**                               null variable as the target file with an 
    //**                               & (e.g. &myfile)
    //**
    //** Returns --> String vw = Name of view
    //**************************************************************************

		//Create a progress bar
		CreateProgressBar("Loading Data from Access - "+tname, "False")

		//Do some input data validation
		if GetFileInfo(dsn_name) = null then return()
		if target_file = null then target_file = GetTempFileName(".bin")
		tmp = SplitPath(target_file)
		if tmp[4] <> ".bin" then do
            ShowMessage('Invalid target file passed to OpenDSN ' + 
                        '(file must be a ".bin" file)')
            Return()
        end
        self.Delete(target_file)
		
		//Open the table and export to the new file
		on notfound do
			Throw("Cannot open " + tname)
			on Error default
			return()
		end
		vw_mdb = OpenTable(tname+"MDB", "ODBC", {dsn_name, tname, index, })
		on notfound default
		ExportView(vw_mdb+"|", "FFB", target_file, ,)
		CloseView(vw_mdb)
		vw = OpenTable(tname, "FFB", {target_file, })
		
		//Return the new view
		DestroyProgressBar()
		Return(vw)
	//EndMethod
	EndItem
	
    //**************************************************************************
    // Create a copy of a TransCAD line layer, updating the ID field to TAZ
	Macro "ZoneID" (dbd_file, out_file, ZoneField, InOpts) do
    //** String dbd_file = Geographic file to process
    //** String out_file = Location of processed file.  If out_file is null
    //**                   or the same as dbd_file, the file will be updated
    //**                   in place.
    //** string ZoneField = Name of the field in the geographic file node
    //**                    layer containing the TAZ ID
    //** Opts.
    //**   integer AddVal = Value to add to maximum zone for non-TAZ numbering
    //**                    (Defaults to 100)
    //**   string ExportSet: Selection set query to export (Defaults to all 
    //**                     features)
    //**
    //** Returns --> (n/a)
    //**************************************************************************

    //Process input =
    if dbd_file = null or GetFileInfo(dbd_file) = null then 
        Throw("UT.ZoneID Error: Geographic File Not found")
    if out_file = null then out_file = dbd_file
    
    cent_qry = "Select * Where " + ZoneField + " > 0"
    
    if InOpts.AddVal != null then do
        if TypeOf(InOpts.AddVal) = 'int' then AddVal = InOpts.AddVal
        else if TypeOf(InOpts.AddVal) = 'double' then AddVal = R2I(InOpts.AddVal)
        else AddVal = 100
    end
    else AddVal = 100
    
    if InOpts.ExportSet != null and TypeOf(InOpts.ExportSet) = 'string' then 
        exp_qry = InOpts.ExportSet
    else exp_qry = null
    
    //Copy the input file to a temporary location for processing
    tmp_file = GetTempFileName(".dbd")
    CopyDatabase(dbd_file, tmp_file)
    
    //Open the geographic network
	RunMacro("TCB Add DB Layers", tmp_file,,)
	Lyrs = RunMacro("TCB get DB line and node layers", tmp_file)
	tmp_node_lyr = Lyrs[1]
	tmp_link_lyr = Lyrs[2]
    
    //Create a temporary field so we can keep track of ID names, then
    //  export the network so ID is TMPID_[RAND] behind the scenes
    //
    // Details:
    // When using ZID as ID, it shows up as ID but is internally named ZID. 
    //    If you try to add a field ZID, it will be named ZID:1 if the ID
    //    field already has this name.  To get around this, we are changing the
    //    old ID field to TMPID_[RAND] and deleting the old ID field (ZID if
    //    the network has already been through this process).
    fld_name = "TMPID_" + Format((RandomNumber()*100), "*.")
    self.AddViewFields({{fld_name, "Integer"}}, tmp_node_lyr, "ID")
    SetDataVector(tmp_node_lyr+"|", fld_name, 
                  GetDataVector(tmp_node_lyr+"|", "ID", ), )
                  
    tmp2_file = GetTempFileName(".dbd")
    //Export the geography
    LF = GetFields(tmp_link_lyr, "All")
    NF = GetFields(tmp_node_lyr, "All")
    INF = GetDBInfo(tmp_file)
    Opts = null
    Opts.[Field Spec] = LF[2]
    Opts.[ID Field] = tmp_link_lyr+".ID"
    Opts.Label = INF[2]
    Opts.[Layer Name] = tmp_link_lyr
    Opts.[Node Name] = tmp_node_lyr
    Opts.[Node Field Spec] = Subarray(NF[2], 2, ) //Excludes the old ID
    Opts.[Node ID Field] = tmp_node_lyr+"."+fld_name
    ExportGeography(tmp_link_lyr+"|", tmp2_file, Opts)
    
    //Delete the temporary file
    DropLayerFromWorkspace(tmp_link_lyr)
    DropLayerFromWorkspace(tmp_node_lyr)
    DeleteDatabase(tmp_file)
    
    //Open the second (updated) temporary file
	RunMacro("TCB Add DB Layers", tmp2_file,,)
	Lyrs = RunMacro("TCB get DB line and node layers", tmp2_file)
	tmp_node_lyr = Lyrs[1]
	tmp_link_lyr = Lyrs[2]
    
    //Create a field called ZID that will contain the zone number for 
    //   centroids and an incrementing number for other nodes.
    self.AddViewFields({{"ZID", "Integer"}}, tmp_node_lyr, "ID")
    SetLayer(tmp_node_lyr)
    cnt_C = SelectByQuery("C", "Several", cent_qry, )
    cnt_NoC = SetInvert("NoC", "C")
    ZV = GetDataVector(tmp_node_lyr+"|C", "Zone", )
    max_z = VectorStatistic(ZV, "Max", )
    SetDataVector(tmp_node_lyr+"|C", "ZID", ZV, )
    NV = Vector(cnt_NoC, "Long", {{"Sequence", max_z+AddVal, 1}})
    SetDataVector(tmp_node_lyr+"|NoC", "ZID", NV, 
                  {{"Sort Order", {{"ID", "Ascending"}}}})
    DeleteSet("C")
    DeleteSet("NoC")
    
    //Select links to export
    SetLayer(tmp_link_lyr)
    if exp_qry != null then do
        cnt = SelectByQuery("ModelLinks", "Several", exp_qry, )
        if cnt = null or cnt = 0 then do
            ShowMessage("Error - Cannot find links based on expansion setting.")
            Return()
        end
    end
    else do
        SelectAll("ModelLinks")
    end
                  
    //Export the geography
    LF = GetFields(tmp_link_lyr, "All")
    NF = GetFields(tmp_node_lyr, "All")
    INF = GetDBInfo(tmp2_file)
    Opts = null
    Opts.[Field Spec] = LF[2]
    Opts.[ID Field] = tmp_link_lyr+".ID"
    Opts.Label = INF[2]
    Opts.[Layer Name] = tmp_link_lyr
    Opts.[Node Name] = tmp_node_lyr
    Opts.[Node Field Spec] = Subarray(NF[2], 2, ) //Excludes the old ID
    Opts.[Node ID Field] = tmp_node_lyr+".ZID"
    ExportGeography(tmp_link_lyr+"|ModelLinks", out_file, Opts)
    
    //Delete the temporary file
    DropLayerFromWorkspace(tmp_link_lyr)
    DropLayerFromWorkspace(tmp_node_lyr)
    DeleteDatabase(tmp2_file)
    
    
	//EndMethod
	EndItem
    
    //**************************************************************************
    // Gets a filename using the Save As dialog box
	Macro "GetSaveAs" (ftype, title, init_dir, init_name) do
    //** This dialog box asks the user for confirmation if a file already exists
    //** and retruns a null (rather than an error) if the user cancels
    //**
    //** Array ftype = File type description formatted as:
    //**               {{"Type Name", "*.ext"}, 
    //**                {"Type Name 2", "*.ext2"}, 
    //**                {...}}
    //** String title: Dialog window title
    //** Optioanl String init_dir: Initial file directory
    //** Optional init_name: Suggested file name
    //**
    //** Returns --> String newname = Name of file (or null if canceled)
    //**************************************************************************
		if right(init_dir, 1) = "\\" then  //remove trailing backslash
			init_dir = left(init_dir, StringLength(init_dir) - 1)

		Opts = {{"Initial Directory",     init_dir},
				{"Suggested Name",        init_name}}

		on escape goto GetSaveCancel
			newname = ChooseFileName(ftype, title, Opts)
		on escape default

		Return(newname)

		GetSaveCancel:
		return(null)
	//EndMethod
	EndItem

    //**************************************************************************
    // Gets a filename using the Open dialog box
	Macro "GetOpen" (ftype, title, init_dir) do
    //**
    //** Array ftype = File type description formatted as:
    //**               {{"Type Name", "*.ext"}, 
    //**                {"Type Name 2", "*.ext2"}, 
    //**                {...}}
    //** String title: Dialog window title
    //** Optioanl String init_dir: Initial file directory
    //**
    //** Returns --> String newname = Name of file (or null if canceled
    //**************************************************************************
		//File Type is: {{"Type Name", "*.ext"}}

		if right(init_dir, 1) = "\\" then  //remove trailing backslash
			init_dir = left(init_dir, StringLength(init_dir) - 1)
		Opts = {{"Initial Directory",     init_dir}}

		on escape goto GetOpenCancel
			newname = ChooseFile(ftype, title, Opts)
		on escape default

		return(newname)

		GetOpenCancel:
		return(null)
	//EndMethod
	EndItem

    //**************************************************************************
    // Choose a directory using the Windows dialog. 
	Macro "ChooseDir" (prompt, init_dir) do
    //** string prompt: Dialog text prompt
    //** Optional string init_dir: Initial file directory
    //** Returns --> String ret_dir = Name of directory (or null if canceled)
    //**************************************************************************
    
		on escape goto canceled
		if right(init_dir, 1) = "\\" then
			init_dir = left(init_dir, StringLength(init_dir) - 1)
		ret_dir = ChooseDirectory(prompt, {{"Initial Directory", init_dir}})
        if right(ret_dir, 1) <> "\\" then ret_dir = ret_dir + "\\"
		return(ret_dir)

		canceled:
		return(null)

	//EndMethod
	EndItem
    
    //**************************************************************************
    // RouteSystemMap: Opens a route system in a new map
    Macro "RouteSystemMap" (rts_file) do
        
        {dbd_file, link_lyr, RtOpts} = GetRouteSystemInfo(rts_file)
        rs_lyr = RtOpts.Name
        {scp, lbl,} = GetDBInfo(dbd_file)
        map = CreateMap(lbl, {"Scope":scp})
        
        if rs_lyr = null then Throw("Error opening route system.")
        
        lyrs = AddRouteSystemLayer(map, rs_lyr, rts_file, )
        RunMacro("Set Default RS Style", lyrs, "True", "True")
        
        Ret = {"Map":map,
              "Routes":lyrs[1], 
              "Stops":lyrs[2],
              "PStops":lyrs[3],
              "Nodes":lyrs[4],
              "Links":lyrs[5]}
              
        Return(Ret)
    
    //EndMethod
    EndItem
	
    //**************************************************************************
    //Delete a matrix index if it exists, do nothing if it doesn't
	Macro "DeleteMtxIndex" (mat, idx_name) do
    //** Matrix mat: Matrix handle
    //** String idx_name: Name of index to delete
    //**************************************************************************

		on NotFound goto DeleteMtxIndexNext
		DeleteMatrixIndex(mat, idx_name)
		DeleteMtxIndexNext:
		on NotFound default
	//EndMethod
	EndItem
    
    //**************************************************************************
    //** Add a core to a matrix, replace/clear the core if it exists
	Macro "AddMtxCore" (mat, CoreName) do
    //** This will not successfully replace the first core in a matrix, as it 
    //** cannot be deleted. In this case, the macro will fail.
    //**
    //** Matrix mat = Matrix handle
    //** String CoreName = Name of core to add
    //**************************************************************************
		on NotFound goto AddMtxCoreNext
		DropMatrixCore(mat, CoreName)
		AddMtxCoreNext:
		on NotFound default
		AddMatrixCore(mat, CoreName)

		Return(1)
	//EndMethod
	EndItem
    
    //**************************************************************************
    //** Return matrix filename and label
    Macro "MatLbl" (fname) do
    //** String fname = matrix filename
    //**
    //** Returns --> Two-element array (fname, matrix_label)
    //**************************************************************************
    
        mat = OpenMatrix(fname, )
        matrix_lbl = mat.Label
        mat = null
        Return({fname, matrix_lbl})
    //EndMethod
    EndItem
	
    //**************************************************************************
    //** Create "Internal" and "External" matrix indices
	Macro "IEIndices" (m_file, vw, i_qry, e_qry, z_id) do
    //** String m_file = matrix filename
    //** String vw = view identifying external stations
    //** String i_qry = query identifying internal zones
    //** String e_qry = query identifying external zones
    //** String z_id = field in view matching default matrix indices
    //**
    //** Returns --> True/False indicating success
    //**************************************************************************
    
        //Open/reference the matrix file
        mat = OpenMatrix(m_file, )
        
        //Make sure the view is open
        v = GetViews()
        v = v[1]
        if ArrayPosition(v, {vw}, ) = 0 then
            Throw("Error: Invalid view name passed to IEIndices")
        else
            SetView(vw)
            
        SelectByQuery("Internal", "Several", i_qry)
        SelectByQuery("External", "Several", e_qry)
        
		//Delete the indices if they already exist
		idxs = GetMatrixIndexNames(mat)
		idxs = idxs[1]+idxs[2] //Combine row and column
		if ArrayPosition(idxs, {"Internal"}, ) > 0 then
			DeleteMatrixIndex(mat, "Internal")
		if ArrayPosition(idxs, {"External"}, ) > 0 then
			DeleteMatrixIndex(mat, "External")
		
		//Create the indices
        CreateMatrixIndex("Internal", mat, "Both", vw+"|Internal", z_id, null, null)
        CreateMatrixIndex("External", mat, "Both", vw+"|External", z_id, null, null)
		
		Return(1)

	//EndMethod
	EndItem
    
    //**************************************************************************
    // Create matrix indices referring to subareas
	Macro "SubareaIndices" (m_file, vw, qrys, sa_names, z_id) do
    //** String m_file = matrix filename
    //** String vw = view identifying subareas
    //** Array qrys = array of queries identifying each subarea
    //** Array sa_names = array of subarea names
    //** String z_id = field in view matching default matrix indices
    //**
    //** Returns --> True/False indicating success
    //**************************************************************************
    
        //Open/reference the matrix file
        mat = OpenMatrix(m_file, )
        
        //Make sure the view is open
        v = GetViews()
        v = v[1]
        if ArrayPosition(v, {vw}, ) = 0 then
            Throw("Error: Invalid view name passed to SubareaIndices")
        else
            SetView(vw)
    
        for i = 1 to sa_names.length do
            //Create a new index
            cnt = SelectByQuery("Sel", "Several", qrys[i])
            if cnt > 0 then  CreateMatrixIndex(sa_names[i], mat, "Both", vw+"|Sel", z_id, null, null)
        end
        
        mat = null
		
		Return(1)

	//EndMethod
	EndItem
	
    //**************************************************************************
    // Replace ID indices with TAZ indices in a matrix
	Macro "TAZIndex" (m_file, vw, u_id, z_id) do
    //** Creates a new copy of a matrix with default ID indices removed and 
    //** TAZ indices added instead.  This requires copying and re-processing of
    //** the matrix file, so it must be fully closed/de-referenced before
    //** proceeding
    //**
    //** String m_file = matrix filename
    //** String vw = the name of an open view containing ID and Zone fields
    //** Array u_id = field in view matching default ID matrix indices
    //** String z_id = field in view containing TAZ numbers
    //**
    //** Returns --> True/False indicating success
    //**************************************************************************
    
    
        //Copy and then open the matrix file
        if FileCheckUsage({m_file}, ) then do
            msg = "Cannot upate indices to TAZ in matrix file Unknown. \n\n" +
                  "File is already open in TransCAD"
            on error goto next
            msg = Substitute(msg, "Unknown", m_file, )
            next:
            on error default
            Throw(msg)
        end
        tmp_file = GetTempFileName(",tmp")
        CopyFile(m_file, tmp_file)
        mat = OpenMatrix(tmp_file, )
        
        //Make sure the view is open
        v = GetViews()
        v = v[1]
        if ArrayPosition(v, {vw}, ) = 0 then
            Throw("Error: Invalid view name passed to TAZIndex")
        else
            SetView(vw)

        //Create a new index
        CreateMatrixIndex("TAZ", mat, "Both", vw+"|", u_id, z_id, null)
        
        //Copy the matrix
        label = GetMatrixInfo(mat)
		label = label[4]
		cores = GetMatrixCoreNames(mat)
		cur = CreateMatrixCurrency(mat, cores[1], "TAZ", "TAZ", )
		Opts = null
		Opts.[File Name] = m_file
		Opts.Label = tmp_label
		Opts.Indices = "Current"
		CopyMatrix(cur, Opts)
		
		Return(True)

	//EndMethod
	EndItem
    
    //**************************************************************************
    //** Opens a matrix and copies it into memory
    Macro "OpenMatrixMem" (mat_file, row_idx, col_idx, Tables) do
    //** mat_file = Matrix file name
    //** row_idex, col_idx = Optional, default is to use default indices
    //** Tables = optional list of cores to open (default is to open all)
    //**
    //** Opening the same matrix more than once without first closing
    //    will probably cause errors
    
        t = SplitPath(mat_file)
        tmp_file = t[1]+t[2]+t[3]+"__MEM__"+t[4]
        
        mat = OpenMatrix(mat_file, )
        cores = GetMatrixCoreNames(mat)
        cur = CreateMatrixCurrency(mat, cores[1], row_idx, col_idx, )

        keepcores = null        
        if Tables != null then do
            for T in Tables do
                idx = ArrayPosition(cores, {T}, )
                if idx > 0 then keepcores = keepcores + {idx}
            end
        end
        
        Opts = null
        Opts.[File Name] = tmp_file
        Opts.Label = mat.Label
        Opts.[Memory Only] = "True"
        if keepcores != null then Opts.Cores = keepcores
        if row_idx != null and col_idx != null then Opts.Indices = "Current"
        
        ret_mat = CopyMatrix(cur, Opts)
        
        mat = null
        cur = null
        
        Return(ret_mat)
    
    
    EndItem //EndMethod
    
    //**************************************************************************
    //** Returns the total from a matrix currency
    Macro "MatrixTotal" (cur) do
        V = GetMatrixVector(cur, {Marginal: "Row Sum"})
        s = VectorStatistic(V, "Sum", )
        Return(s)
    enditem //EndMethod

    //**************************************************************************
    //** Returns a nicely formatted date and time
	Macro "FormatDate" (daytime, InOpts) do
    //** Optional string daytime = Day/Time formatted as returned by 
    //**                           GetDateAndTime(). Uses the current date/time
    //**                           if ommitted.
    //**
    //** Returns --> String RetVal = Formatted date and time
    //**  if Opts.Sortable then return YYYY-MM-DD TT_TT_TT
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
        
		//Define month strings
		NumMonths.Jan = "01"
		NumMonths.Feb = "02"
		NumMonths.Mar = "03"
		NumMonths.Apr = "04"
		NumMonths.May = "05"
		NumMonths.Jun = "06"
		NumMonths.Jul = "07"
		NumMonths.Aug = "08"
		NumMonths.Sep = "09"
		NumMonths.Oct = "10"
		NumMonths.Nov = "11"
		NumMonths.Dec = "12"
        
        //Sortable version
        if InOpts.Sortable then do
        
            dt = JoinStrings({year, NumMonths.(mth), num}, "-") + " " + Substitute(time, ":", "", )
            Return(dt)
        
        end

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
    //**  FormatTime: Converts seconds of time into hr:min:sec
    Macro "FormatTime" (tot_time) do
    
        hr = Floor(tot_time/3600)
        min = Floor((tot_time-hr*3600) / 60)
        sec = tot_time - hr*3600 - min*60
        run_time = Format(hr, "*00.") + ":" + Format(min, "00.") + ":" + Format(sec, "00.")
        
        Return(run_time)
    
    EndItem //EndStep
	
    //**************************************************************************
    // Close any left-over progress bars
	Macro "KillBars" do
		on notfound do
				keepgoing = 0
				goto KillBarsNext
			end
			FoundBar = 0
			keepgoing = 1
			bars = 0
			while keepgoing = 1 and bars < 5 do
				DestroyProgressBar()
				FoundBar = 1
				bars = bars + 1
			end
		KillBarsNext:
		on notfound default
		if FoundBar = 1 then ResetProgressWindow()

		//Reset status bar title to "Status"
		SetProgressWindow("Status", 2)
		ResetProgressWindow()
	//EndMethod
	EndItem
	
    //**************************************************************************
    //** Delete the named file and then returns the filename.
	Macro "Delete" (del_file) do
    //** Delete individual files, FFB files, or DBD files.  Attempt to delete
    //** all associated files for FFB and DBD files, but do not fail if one or
    //** files are already missing (e.g., bin file is present but dcb is not).
    //** This utility is used to clear old files in macro initialization.
    //**
    //** String del_file = Full pathname of file to delete
    //**
    //** Returns --> del_file = Same as input
    //**************************************************************************

		if GetFileInfo(del_file) <> null then do
			tmp = SplitPath(del_file)

			//if a database, delete all associated files
			if tmp[4] = ".dbd" then do
				ext = {".dbd", ".ipx", ".sty", ".r1", ".r0", ".pts", ".pnk", 
                       ".lok", ".grp", ".dsk", ".des", ".dcb", ".cdd", ".bx", 
                       ".bin"}
				n_ext = {".sty", ".dcb", ".bx", ".bin"}

				for i = 1 to ext.length do
					file = tmp[1]+tmp[2]+tmp[3]+ext[i]
					if GetFileInfo(file) <> null then DeleteFile(file)
				end
				for i = 1 to n_ext.length do
					file = tmp[1]+tmp[2]+tmp[3]+"_"+n_ext[i]
					if GetFileInfo(file) <> null then DeleteFile(file)
				end
			end

			//If a FFB Table
			else if tmp[4] = ".bin" then do
				dcb_file = tmp[1]+tmp[2]+tmp[3]+".DCB"
				if GetFileInfo(dcb_file) <> null then DeleteFile(dcb_file)
			end

			//any other file type
			else do
				DeleteFile(del_file)
			end
		end

		Return(del_file)

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
    
    //**************************************************************************
    //** Returns the type of a table for use in OpenTable baesd on the filename
    Macro "TableType" (fname) do
    //** String fname = Filename to check
    //**
    //** Returns -> String Type = DBASE, FFA, FFB, CSV, EXCEL (Other types are 
    //**                          not supported - will return null)
    //**************************************************************************
        
        e = SplitPath(fname)
        e = Lower(e[4])
        if e = ".dbf" then Return("DBASE")
        if e = ".bin" then Return("FFB")
        if e = ".asc" then Return("FFA")
        if e = ".csv" then Return("CSV")
        if e = ".xls" or e = ".xlsx" or e = ".xlsm" then Return("EXCEL")
        
        Return()
    //EndMethod
    EndItem
    
    //**************************************************************************
    //** Opens a table into a view, figuring out the filetype and view name based on the filename
    Macro "OpenView" (fname) do
    //** String fname = Filename to open
    //** Returns -> String view name
    //**
    //** View name is based on filename (C;\...\*ViewName*.[type]
    //** Table type must be listed in the TableType method above
    
        //Check for file existence
        if GetFileInfo(fname) = null then do
            Throw(JoinStrings({"File Not Found:", fname}, " "))
            Return()
        end
        
        //Detect and check table type
        typ = self.TableType(fname)
        if typ = null then do
            Throw(JoinStrings({"Unknown Table Type:", fname}, " "))
            Return()
        end
        
        t = SplitPath(fname)
        vw = OpenTable(t[3], typ, {fname})
        
        Return(vw)
        
        
    //EndMethod
    EndItem
    
    //**************************************************************************
    //** Returns a list of the select query names in a .qry file
    Macro "SelectList" (qry_file) do
    //** String qry_file = path and filename to select link query file
    //** 
    //** Returns -> Array qry_list = list of query names in the file
    //**
    //** NOTE: This is compatible with the query file format generated by 
    //**       TransCAD 5, but is **NOT** fully XML compliant.  This simple
    //**       appraoch simply looks for <name>****</name> and returns a list
    //**       of identified names.  The name tags and name CAN NOT be split 
    //**       across lines.
    //**************************************************************************
    
    //check for a select query file 
    if GetFileInfo(qry_file) = null then do
        Throw("No select query file found for this scenario")
    end
    
    fp = OpenFile(qry_file, "r")
    lines = ReadArray(fp)
    CloseFile(fp)
    
    StartTag = '<name>'
    EndTag = '</name>'
    
    qry_list = null
    for i = 1 to lines.length do
        l = lines[i]
        pos = Position(l, StartTag)
        if pos > 0 then do
            pos = pos + Len(StartTag)
            epos = PositionFrom(pos, l, EndTag)
            name = Substring(l, pos, epos-pos)
            qry_list = qry_list + {name}
        end
    end
    
    Return(qry_list)
    
    EndItem
    //EndMethod
        
	//**************************************************************************
	//** Macro to apply a FT color theme and save settings to the DBD file
    //** !!! !!! THIS MACRO SHOULD BE MOVED TO A MAPPING UTILITY !!! !!!
	Macro "NetworkSetting" (dbd_file, InOpts) do
	//** String dbd_file = Name of the network file
	//** Opts
	//** 	.FT_Field = String = Name of facility type field
	//**	.FT_List = Array = List of valid FT values
	//**	.FT_Desc = Array = List of FT Names (Do not include 
    //**                       '# - Name', just include 'Name')
	//** 	.FT_Style = Array = List of style names (null=default, solid=force 
    //**                        solid, dash=dash --> All others will result in 
    //**                        default)
	//**	.FT_Color = Array = List of FT Colors
	//**	.FT_Width = Array = List of FT line widths
	//**	.Centroid = Number = Centroid Connector Facility Type Value
    //**************************************************************************
	
		//List of possible color values
		Colors = null
		Colors.Gray = ColorRGB(49152,49152,49152) //The standard "TransCAD Gray"
		Colors.Black = ColorRGB(0, 0, 0)
		Colors.BlueGreen = ColorRGB(0, 49152, 49152)
		Colors.Red = ColorRGB(65535, 0, 0)
		Colors.Green = ColorRGB(0, 49512, 0)
		Colors.Blue = ColorRGB(0, 0, 65535)
		Colors.LtBlue = ColorRGB(0, 44032, 65535)
		Colors.Orange = ColorRGB(65535, 49152, 0)
	
		//Open the dbd file in a map
		map = RunMacro("G30 new map",dbd_file, "False")
		Lyrs = RunMacro("TCB get DB line and node layers", dbd_file)
		node_lyr = Lyrs[1]
		link_lyr = Lyrs[2]
		map = GetMap()
		SetMapRedraw(map, "False")
		
		//Remove any pre-existing link themes (but let node themes be)
		RedrawMap() //The map must be redrawn before the themes can be removed
		pre_themes = GetThemes(link_lyr)
		For i = 1 to pre_themes.length do
			HideTheme( , pre_themes[i])
			DestroyTheme(pre_themes[i])
		end
		
		//Create the theme
		ft_theme = CreateTheme("Roadways", link_lyr+"."+InOpts.FT_Field, 
                               "Categories", InOpts.FT_List.length, )
		
		//Set theme class labels
		dim ft_labels[InOpts.FT_List.Length + 1]
		ft_labels[1] = "Other"
		for i = 2 to ft_labels.length do
			ft_labels[i] = string(InOpts.FT_List[i - 1]) + " - " + 
                           InOpts.FT_Desc[i - 1]
		end
		SetThemeClassLabels(ft_theme, ft_labels)
		
		//Set line styles
		sty_list = RunMacro("G30 setup line styles")
		solid = sty_list[2]
		dash = sty_list[6]
		dim ft_styles[InOpts.FT_List.Length + 1]
		ft_styles[1] = null  //Use default style for "Other"
		for i = 2 to ft_styles.length do
			if Lower(InOpts.FT_Style[i - 1]) = "solid" then 
                ft_styles[i] = solid
			else if Lower(InOpts.FT_Style[i - 1]) = "dash" then 
                ft_styles[i] = dash
			//null by default
		end
		SetThemeLineStyles(ft_theme, ft_styles)
		
		//Set colors
		dim ft_colors[InOpts.FT_List.Length + 1]
		ft_colors[1] = null //Default for "Other"
		for i = 2 to ft_colors.length do
			ft_colors[i] = Colors.(InOpts.FT_Color[i - 1])
		end
		SetThemeLineColors(ft_theme, ft_colors)
		
		//Set Widths
		dim ft_widths[InOpts.FT_List.Length + 1]
		ft_widths[1] = null //Default for "Other"
		for i = 2 to ft_widths.length do
			ft_widths[i] = InOpts.FT_Width[i - 1]
		end
		SetThemeLineWidths(ft_theme, ft_widths)
		
		//Show the theme
		ShowTheme( , ft_theme)
		
		//Set the map to redraw
		SetMapRedraw(map, "True")
		
		//Save the theme as the default display for the link layer
		t = SplitPath(dbd_file)
		sty_file = t[1]+t[2]+t[3]+".sty"
		SetDefaultDisplay(link_lyr, sty_file)
		
		CloseMap(map)
		
			
				
	
	//EndMethod
    EndItem
    
    //**************************************************************************
	//** Checks a skim matrix for disconnected zones, writes to Report File
    //** !!! !!! Consider moving to a comprehesive input check utility !!! !!!
	Macro "SkimCheck" (cur) do
    //** Matrix Currency cur = Matrix currency to check (must be square with a
    //**                       consistent row and column index)
    //**
    //** Returns --> Bool = True if OK, False if problems were found
    //**************************************************************************
	
		//Start report file
		AppendToReportFile(0, "", {{"Section", "True"}, {"Title", "TAZ Connectivity Check"}})
		
		//Maximum of 20 zones will be listed
		MaxMessage = 20
	
		//Load vectors
        //row and col indexes MUST match (not checked)
		RowIdx = GetMatrixVector(cur, {{"Index", "Row"}})
		RowSum = GetMatrixVector(cur, {{"Marginal", "Row Sum"}})
		ColSum = GetMatrixVector(cur, {{"Marginal", "Col Sum"}})
		
		//Check each zone
		MissedZones = null
		for I = 1 to RowIdx.Length do
			if nz(RowSum[I]) = 0 or nz(ColSum[I]) = 0 then 
                MissedZones = MissedZones + {RowIdx[I]}
		end
		
		if MissedZones = null then do
			AppendToReportFile(2, "No Problem Zones Found", {{"Bold", "True"}, 
                                                             {"Background", 
                                                              "Dark"}})
			CloseReportFileSection()
			Return(True)
		end
		else do
			AppendTableToReportFile({{"Name", "Disconnected TAZ"}}, 
                                     {{"Title", "Disconnected Zones Found"}, 
                                      {"Indent", 2}})
			for i = 1 to Min(MissedZones.Length, MaxMessage) do
				AppendRowToReportFile({MissedZones[i]}, )
			end
			If MissedZones.Length > MaxMessage then 
                AppendToReportFile(2, string(MissedZones.Length-MaxMessage) + 
                " Additional problem zones found", {{"Background", "Light"}})
                
			CloseReportFileSection()
			Return()
		end
	
	//EndMethod
    EndItem
    
    //****************************************************************
    //	Replacement TAG function
    Macro "QuickTag" (target_lyr, target_fld, src_lyr, src_fld) do

	//Initialize the taget field to null
	SetDataVector(target_lyr+"|", target_fld, Vector(GetRecordCount(target_lyr,), "Long", ), ) //Clear field
	VALS = GetDataVector(src_lyr+"|", src_fld, )
	VALS = SortVector(VALS, {{"Unique", "True"}})

	//Select target records enclosed by source records, then populate with values
	CreateProgressBar("QuickTag", )
	for ii = 1 to VALS.length do
		UpdateProgressBar("QuickTag", R2I(ii/VALS.length * 100))
		SetLayer(src_lyr)
        if VALS[ii] = null then sel_qry = "Select * Where " + src_fld + " = null"
        else sel_qry = "Select * Where " + src_fld + " = " + String(VALS[ii])
		src_cnt = SelectByQuery("SRCset", "Several", sel_qry, )
		if src_cnt > 0 then do
			merged_area = GetMergedArea(src_lyr+"|SRCset", {{"Progress Message", "Set "+String(VALS[ii])}})
			SetLayer(target_lyr)
			cnt = SelectByShape("TGTSet", "Several", merged_area[3], {{"Inclusion", "Enclosed"}})
			if cnt > 0 then SetDataVector(target_lyr+"|TGTSet", target_fld, Vector(cnt, "Long", {{"Constant",VALS[ii]}}), )
		end
	end

	//Use the standard tag function to fill in any leftovers (e.g., records spanning multiple values)
	UpdateProgressBar("Tagging leftovers", 99)
	SetView(target_lyr)
	SelectByQuery("Leftovers", "Several", "Select * Where " + target_fld + " = null", )
	TagLayer("Value", target_lyr+"|Leftovers", target_lyr+"."+target_fld, src_lyr, src_lyr+"."+src_fld)
	DeleteSet("Leftovers")
	DestroyProgressBar()
    
//EndMethod
    EndItem
    
    //****************************************************************
    //Calculate link area type based on TAZ area type
    Macro "CalcLinkAT" (link_lyr, taz_lyr, InOpts) do
        //Opts:
        //.LinkField: Field name on link layer
        //.ZoneField: Field name on taz layer
        //.Buffer: 0 for simple tag, or real value buffer in miles for dense AT tagging
        //.Override: {{Query, Value}} pairs to override calculated AT
        //.Default: Set AT to this value if not found from the procedure

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
        SetDataVector(link_lyr+"|", link_fld, Vector(cnt, "Long", ), )
        
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
                ATs[ii] = AT2[AT2.length - ii]
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
                cnt = SelectByQuery("ATL", "Subset", "Select * Where "+link_fld+" > " + String(AT), {{"Inclusion", "Enclosed"}})
             
                //Fill the selected layers
                if cnt > 0 then SetDataVector(link_lyr+"|ATL", link_fld, Vector(cnt, "Integer", {{"Constant", AT}}), )
                
                DropLayer(GetMap(), buff_lyr)
                if !Verbose then DeleteDatabase(buff_file)
                
            end
            DropLayer(GetMap(), dist_lyr)
            if !Verbose then DeleteDatabase(dist_file)
        
        end
        
        //Process override
        if InOpts.Override != null then do
            OR = InOpts.Override
            SetView(link_lyr)
            for kv in OR do
                {qry, val} = kv
                cnt = SelectByQuery("Override", "Several", qry)
                if cnt > 0 then do
                    SetDataVector(link_lyr+"|Override", link_fld, Vector(cnt, "Long", {{"Constant", val}}), )
                end
            end
            DeleteSet("Override")
        end
        
        //Set any remaining blank area type values to the default value
        if InOpts.Default != null then do
            cnt = SelectByQuery("Default", "Several", "Select * Where "+link_fld+" = null")
            if cnt > 0 then do
                SetDataVector(link_lyr+"|Default", link_fld, Vector(cnt, "Long", {{"Constant", InOpts.Default}}), )
            end
            DeleteSet("Default")
        end

    EndItem //EndMethod
    
    //****************************************************************
    //Calculate link area type based on TAZ area type
    Macro "CalcRampAT" (link_lyr, node_lyr, ramp_qry, Opts) do
        //Opts.[AT Field] = Field containing area type (defaults ot AT)
        
        //Process Opts
        if Opts.[AT Field] = null then do
            at_fld = "AT"
        end else do
            at_fld = Opts.[AT Field]
        end

        //Select all ramps to be processed
        SetLayer(link_lyr)
        SelectByQuery("Ramps", "Several", ramp_qry, )
        
        //Create A and B node fields
        CreateNodeField(link_lyr, "AN", node_lyr+".ID", "From", )
        CreateNodeField(link_lyr, "BN", node_lyr+".ID", "To", )
        
        repeat = 1
        iters = 0
        //Repeat this process until nothing changes
        while repeat do
            repeat = 0
            
            //Load data into vectors
            R = GetDataVectors(link_lyr+"|Ramps", {"ID", at_fld, "AN", "BN"}, {{"Return Options Array", "True"}})
            L = GetDataVectors(link_lyr+"|", {"ID", at_fld, "AN", "BN"}, {{"Return Options Array", "True"}})
            
            //Check each ramp
            for II = 1 to R.ID.length do
                
                //Vector of area types on connected links
                ATV = if (L.AN=R.AN[II] or L.AN=R.BN[II] or L.BN=R.AN[II] or L.BN=R.BN[II]) then L.(at_fld) else null
                MinAT = VectorStatistic(ATV, "Min", )
                
                //Set AT to lower value if found in connected links
                // (Do not change to or from zero area type)
                r_AT = R.(at_fld) //workaround since we can't use Opts.(str_value)[idx]
                if MinAT > 0 and r_AT[II] > 0 and MinAT < r_AT[II] then do
                    repeat =  1
                    r_AT[II] = MinAT
                end //if need to change
            end //II
            SetDataVector(link_lyr+"|Ramps", at_fld, r_AT, )
            
            iters = iters + 1
        end //while repeat
        
    enditem //EndMethod


    //****************************************************************
    //Period template expansion function
    Macro "Expand" (template, Opts) do
    
        //Options:
        // - NestOrder = array of template strings to define array nesting order.  
        //    for example {"PER_TRN", "TMODE"} will produce ret[per][tmode]
        //    BUT: If NestOrder is passed, only named patterns will be expanded.
        //   
        // Default is to expand in the order ExpandSettings is originally defined.
    
        //Settings (Must be set externally before use)
        shared Scen
        Sets = Scen.ExpandSettings
        
        if Opts.NestOrder != null then do
            UseSets = null
            for ii = 1 to Opts.NestOrder.length do
                k = Opts.NestOrder[ii]
                UseSets = UseSets + {{k, Sets.(k)}}
            end
        end else do
            UseSets = CopyArray(Sets)
        end
        
        ret = template
        for kv in UseSets do
            key = kv[1]
            val = kv[2]

            ret = self.ExpandHelper(ret, key, val)
                
        end
        
        Return(ret)
    
    enditem
    //EndMethod
    
    //****************************************************************
    //Flatten a multi-dimesion array into a 1D array
    Macro "FlattenArray" (arr) do
    
        fa = null
        for ii = 1 to arr.length do
            if TypeOf(arr[ii]) != 'array' then do
                fa = fa + {arr[ii]}
            end else do
                tmp = self.FlattenArray(arr[ii])
                fa = fa + tmp
            end
        end
        
        return(fa)
    EndItem //EndMethod
    
    //for use only when called from Expand
    Macro "ExpandHelper" (template, key, vals) do
    
        k = "%"+key+"%"
        
        //If template is a string, expand the string and return an array
        if TypeOf(template) = 'string' then do
        
            //Return original if key not found
            if Position(template, k) = 0 then Return(template)
    
            //Expand to array if key found
            dim ret[vals.length]
            for ii = 1 to vals.length do
                ret[ii] = Substitute(template, k, vals[ii], )
            end
            
            Return(ret)
        end
        
        //If template is an array, recursively expand each array element
        if TypeOf(template) = 'array' then do
            dim ret[template.length]
            for ii = 1 to template.length do
                ret[ii] = self.ExpandHelper(template[ii], key, vals)
            end
            
            Return(ret)
        end
    
    enditem
    //EndMethod

    //**************************************************************************    
    //** Shows an integer, real, string, null, array, Opts, etc.
    Macro "ShowValue" (val) do
    
        ty = TypeOf(val)
        if ty = 'int' then ShowMessage('Integer: \n\n' + Format(val, "*,."))
        else if ty = 'double' then ShowMessage('Double: \n\n' + Format(val, "*,.0#####"))
        else if ty = 'string' then ShowMessage('String: \n\n' + val)
        else if ty = null then ShowMessage('null')
        else if ty = 'array' then do
            if self.IsOpt(val) then RunDbox("ShowTree", self.TreeOpt(val))
            else ShowArray(val)
        end
        else ShowMessage('<'+ty+'>')
    
    enditem //EndMethod
    
    //**************************************************************************
    //** Create a tree variable to display an Opts array
    Macro "TreeOpt" (Opts) do

        //Only continue if the passed array is a proper Opts array.
        if !self.IsOpt(Opts) then Return()

        Tree = null

        //Process each element in the array
        for _opt = 1 to Opts.length do
            opt = Opts[_opt]
            key = opt[1]
            val = opt[2]
                
            if self.IsOpt(val) then do
                Tree.(key) = self.TreeOpt(val)
            end
            else do
            
                //Convert value to string for display
                ty = TypeOf(val)
                if ty = 'int' then strval = Format(val, "*,.")
                else if ty = 'double' then strval = Format(val, "*,.0000")
                else if ty = 'string' then strval = val
                else if ty = 'null' then strval = 'null'
                else if ty = 'array' then strval = '<array>'
                else strval = '<'+ty+'>'
                
            
                keyval = key + ' = ' + strval
                Tree.(keyval) = val
            end
                
        end

        Return(Tree)
        

    enditem //EndMethod
        
    //**************************************************************************
    //** Returns True/False indicating if an array is a proper options array
    Macro "IsOpt" (Opts) do

        if TypeOf(Opts) != 'array' then Return(False)
        for _opt = 1 to Opts.Length do
            opt = Opts[_opt]
            if TypeOf(opt) != 'array' then Return(False)
            if opt.Length != 2 then Return(False)
            if TypeOf(opt[1]) != 'string' then Return(False)
        end
        
        //If we're still going, return True.
        Return(True)
        
        
    enditem //EndMethod

    //**************************************************************************
    //** Returns output route system path/name
    Macro "OutputRTS" (inrts_file, tdbd_file) do
    //** inrts_file: Input route system filepath (for name+extension)
    //** tdbd_file: dbd file where route system is located (for path only)
    
    //Note: the rts output file is not deleted.  Deleting the rts file occasionally 
	//      resulted in deletion of input files when the model crashed and was restarted.
    //      Keeping the name here rather 
    
	//Define the (output copy of) route system file
	//**Special case - uses the name from the input file - needed for rts copy**
	outtmp = SplitPath(tdbd_file)
	intmp  = SplitPath(inrts_file)
	rts_file = outtmp[1]+outtmp[2]+intmp[3]+intmp[4]
    
    return(rts_file)
    
    enditem //EndMethod
    
    
    //**************************************************************************
    //** Returns output route system path/name
    Macro "ReadParams" (param_file, key, column, segment, qry) do
        //segment: - Null for a non-sgmented parameter file
        //         - Field name for segmented parameters (must be numeric)
        //query: - null to use all records
        //       - Query including Select * Where to limit to selected records
        
        param_vw = self.OpenView(param_file)
        ret = null
        
        cur_vw = GetView()
        SetView(param_vw)
        
        if qry != null then do  
            SelectByQuery("P", "Several", qry)
            set = "|P"
        end else do
            SelectAll("P")
        end
        
        
        if segment = null then do
        
            {key, val} = GetDataVectors(param_vw+"|P", {key, column}, )
            
            for ii = 1 to key.length do
                ret.(key[ii]) = val[ii]
            end
        end else do
        
            SetView(param_vw)
            SelectByQuery("S", "Several", "Select * Where " + segment + " > 0", {{"Source And", "P"}})
            CreateExpression(param_vw, "KEY_SEG", "JoinStrings({"+key+", " + segment + "}, '_')", )
            
            {key, seg} = GetDataVectors(param_vw+"|S", {key, segment}, )
            
            //Unique parameters and segments
            keys = SortVector(key, {{"Unique", "True"}})
            segs = SortVector(seg, {{"Unique", "True"}})
            max_seg = VectorStatistic(segs, "Maximum", )
            if TypeOf(max_seg) != "int" then max_seg = R2I(max_seg)
            
            //Get all parameters
            for kk = 1 to keys.length do
                dim tmp[max_seg]
                for ss = 1 to segs.length do
                    rec = LocateRecord(param_vw+"|S", "KEY_SEG", {JoinStrings({keys[kk], segs[ss]}, "_")}, {{"Exact", "True"}})
                    if rec != null then tmp[ss] = param_vw.(column)
                end //ss
                ret.(keys[kk]) = CopyArray(tmp)
                tmp = null
            end //kk
        end //segmented
        
        //Leave view as we started
        if cur_vw != null then SetView(cur_vw)

        CloseView(param_vw)
        Return(ret)
    
    enditem //EndMethod
    
    
    //**************************************************************************
    //** Clear a directory, create if it doesn't exist
    Macro "ClearDir" (path) do
    // path can have a trailing backslash, but it is optional
    
    //Prevent attempts to delete everything in the program
    //  files path if noting is passed
    if path = null or path = "\\" then do
        Throw("Invalid/blank path passed to ClearDir")
        Return()
    end
    
    //allow missing trailing backslash
    if Right(path, 1) != "\\" then path = path + "\\"
    
    //Create/clear the Model directory...
    tmp = left(path, len(path) - 1)  //w/o trailing backslash
    exist = GetDirectoryInfo(tmp+"*", "Directory")
    files = GetDirectoryInfo(path+"*", "File")
    if !exist then do
    CreateDirectory(path)
    end else if files != null then do
        for f in files do
            DeleteFile(path + f[1])
        end
    end
    
    enditem //EndMethod
    
    
    Macro "Fratar" (cur, RowTot, ColTot, InOpts, Ret) do
    
        //Exit on user cancellation
        on escape do
            Return(0)
        end

        conv = if InOpts.Convergence = null then 0.001 else InOpts.Convergence
        limit = if InOpts.IterLimit = null then 25 else InOpts.IterLimit
        err = null
        
        RowTot.ColumnBased = True
        ColTot.RowBased = True
        
        //Ret (to send back convergence information)
        Ret = null
        for iter = 1 to limit do
            if err != null then prev_err = err
        
            msg = "Fratar: " + String(iter) + " / " + String(limit)
            if err != null then msg = msg + " (" + String(err) + ")"
            SetStatus(2, msg, )
        
            //Factor Rows
            RowSum = GetMatrixVector(cur, {{"Marginal", "Row Sum"}})
            RowFac = if RowSum = 0 then 1 else (RowTot / RowSum)
            cur := cur * RowFac
            
            //FactorColumns
            ColSum = GetMatrixVector(cur, {{"Marginal", "Column Sum"}})
            ColFac = if ColSum = 0 then 1 else (ColTot / ColSum)
            cur := cur * ColFac
            
            //Check % col error (pre-factor) and exit loop if converged
            err = VectorStatistic(Abs(ColFac - 1), "Max", )
            if err < conv then break
            
            if err = prev_err then break //stuck: error stoped changing
        end
        
        //Final row factor so row totals are always matched
        RowSum = GetMatrixVector(cur, {{"Marginal", "Row Sum"}})
        RowFac = if RowSum = 0 then 1 else (RowTot / RowSum)
        cur := cur * RowFac
        
        Ret.Err = err
        Ret.Iter = iter
        if err < conv then Ret.Converged = "True"
        else Ret.Converged = "False"
        
        SetStatus(2, "@System1", )
        
        Return(1)

    enditem //EndMethod
    
    //**************************************************************************
    //** Create list for spinner, limited by low and high values
    Macro "SpinnerList" (val, step, low) do
    
         val = R2I(Max(low, val))
         spinnerlist = {r2s(val)}
         if val - step >= low then spinnerlist = {r2s(val - step)} + spinnerlist
         //if val + step <= high then spinnerlist = spinnerlist + {r2s(val + step)}
         spinnerlist = spinnerlist + {r2s(val + step)}

         Return({val, String(val), spinnerlist})
    
    enditem //EndMethod
        
	//**************************************************************************
	//** Run TLFD for a list of purposes/segments and write to a .bin file
	Macro "CalcTLFD" (trip_file, skim_file, skim_core, out_file, InOpts) do
	//** string trip_file = matrix file with trips.  TLFD will be reported for all cores.
	//** string skim_file = matrix file with skims.
	//** string skim_core = core name to use for impedance.
	//** string out_file = file where results should be saved
	//** Opts.MinBin = minimum bin number (defaults to 0)
	//** Opts.MaxBin = maximum bin number (defaults to 100)
	//** Opts.BinSize = bin size (defaults to 1)
	//** Opts.Tables = Array of core names to summarize (defaults to all cores)
	//** Opts.Period = String indicating period (for label only, ok to omit)
	//** Opts.Skims.<Core> = {File, core} //Skim file/core override by trip table core
    //** Opts.[Trip Index] = Trip matrix index (optional)
    //** Opts.[Trip Index] = Skim matrix index (optional)
	// self
	// Params/Opts are not type checked or verified to have valid contents.
	
        //Process Opts
        MinBin = if InOpts.MinBin != null then InOpts.MinBin else 0
        MaxBin = if InOpts.MaxBin != null then InOpts.MaxBin else 200
        BinSize = if InOpts.BinSize != null then InOpts.BinSize else 1
        Tables = if InOpts.Tables != null then CopyArray(InOpts.Tables) else null
        per = if InOpts.Period != null then InOpts.Period else ""
        SkimOR = if InOpts.Skims != null then InOpts.Skims else null
        
        skim_idx = if InOpts.[Skim Index] != null then InOpts.[Skim Index] else {,}
        trip_idx = if InOpts.[Trip Index] != null then InOpts.[Trip Index] else {,}
        
        //Get core names
        mat = OpenMatrix(trip_file, )
        allcores = GetMatrixCoreNames(mat)
        mat = null
        
        //Filter cores to defined tables only
        if Tables != null then do
            cores = null
            for ii = 1 to allcores.length do
                if ArrayPosition(Tables, {allcores[ii]}, ) > 0 then cores = cores + {allcores[ii]}
            end
        end else cores = allcores
        
        //Get working directory
        t = SplitPath(out_file)
        dir = t[1] + t[2]
        
        //Initialize output table info
        Fields = {{"BIN", "Integer", 10, }}
        Vs = null
        Vs.Bin = Vector(MaxBin, "Long", {{"Sequence", 1, 1}})
        
        for _core = 1 to cores.length do
            core = cores[_core]
            
            //Set up table field name
            Fields = Fields + {{per+core, "Real", 10, 2}}
            
            //Check for skim override
            if SkimOR.(core) = null then do
                skim_usefile = skim_file
                skim_usecore = skim_core
            end else do
                t = SkimOR.(core)
                skim_usefile = t[1]
                skim_usecore = t[2]
            end
            
            //run TLD procedure
            Opts = null
            Opts.Input.[Base Currency] = {trip_file, core, trip_idx[1], trip_idx[2]}
            Opts.Input.[Impedance Currency] = {skim_usefile, skim_usecore, skim_idx[1], skim_idx[2]}
            Opts.Global.[Start Value] = MinBin
            Opts.Global.[End Value] = MaxBin
            Opts.Global.Size = BinSize
            Opts.Global.[Min Value] = 1 //ignore below min
            Opts.Global.[Max Value] = 0 //don't ignore over max
            Opts.Global.[Create Chart] = 0
            Opts.Output.[Output Matrix].Label = per + core+" TLFD"
            Opts.Output.[Output Matrix].Compression = 1
            tmp_file = dir + "__TEMP__TLFD_" + per + core + ".mtx"
            Opts.Output.[Output Matrix].[File Name] = tmp_file

            ret_value = RunMacro("TCB Run Procedure", "TLD", Opts, &Ret)
            if !ret_value then Return()
            Ret = null
            
            //Load results into a vector, then delete temp file
            mat = OpenMatrix(tmp_file, )
            cur = CreateMatrixCurrency(mat, "TLD", , , )
            Vs.(per+core) = GetMatrixVector(cur, {{"Column", 1}})
            mat = null
            cur = null
            DeleteFile(tmp_file)
            
            
        end
        
        //Write results to a table
        tlfd_vw = CreateTable("TLFD", out_file, "FFB", Fields)
        AddRecords(tlfd_vw, , , {{"Empty Records", MaxBin}})
        SetDataVectors(tlfd_vw+"|", Vs, )
        CloseView(tlfd_vw)
        
        Return(1)
	
	
	enditem //EndMethod - CalcTLFD
        
	//**************************************************************************
	//** Attach traffic counts in a view to the network
    
    Macro "AttachCounts" (link_lyr, count_vw) do
    
        //Input: 
        // link_lyr = Open link layer
        // count_vw = count view open in the workspace
        //Returns:
        // name of joined view with counts
        
        join_vw = JoinViews(link_lyr+"+"+count_vw, link_lyr+".ID", count_vw+".ID", )
        
        pers = {"AM", "PM", "MD", "EV", "EA"}
        dirs = {"AB", "BA"}
        classes = {"AUTO", "LTRK", "MTRK", "HTRK"}
        
        //Define count expressions
        // CountAction = 0 --> use validation count if present, fall back on cutline count if needed.
        // CountAction = 1 --> Do not use validation count, use cutline count, but only if present.
        // CountAction = -1 --> Do not use any count data.
        
        //Map: Show all counts, even those that are disabled
        map_exp = "if (CountAction = 1 and CL_TOT > 0) then CL_TOT else if DAILY > 0 then DAILY else CL_TOT"
        
        //Report counts: Remove disabled counts
        dy_exp = "if nz(CountAction) = 0 then (if DAILY > 0 then DAILY else CL_TOT) " + 
                  "else if CountAction = 1 then CL_TOT else null"
                  
        per_exp = "if nz(CountAction) = 0 then %DIR%_%PER%PKPER else null"
        //and nz(two_way) = 0
        class_exp = "if nz(CountAction) = 0 or nz(CountAction) = 1 then CL_%CLASS% else null"
        
        //Create expressions in view
        CreateExpression(join_vw, "MAP_COUNT", map_exp, )
        CreateExpression(join_vw, "VAL_COUNT", dy_exp, )
        
        //Period by direction
        for p in pers do
            add_flds = null
            for d in dirs do
            
                exp = Substitute(per_exp, "%PER%", p, )
                exp = Substitute(exp, "%DIR%", d, )
                
                fld = CreateExpression(join_vw, d+"_COUNT_"+p, exp, )
                add_flds = add_flds + {"nz("+fld+")"}
            
            end
            
            //... and total for period
            CreateExpression(join_vw, "TOT_COUNT_"+p, "zn("+JoinStrings(add_flds, " + ")+",)", )
        end
        
        //Class counts
        for c in classes do
            exp = Substitute(class_exp, "%CLASS%", c, )
            CreateExpression(join_vw, "CLASS_COUNT_"+c, exp, )
        end
        
        Return(join_vw)
    
    enditem //EndMethod
        
EndClass  //end class "Utilities"

//******************************************************************************
//** ShowTree: Support dialog box to show a tree diagram                      **
Dbox "ShowTree" (Tree) resize title: "Options Array"
    init do
        UT = null
        UT = CreateObject('Utilities')
        selval = null
    enditem
    
    tree view "View" 1, 1, 50, 20 List: Tree Variables: TreeSel resize: height, width do 
        if TypeOf(TreeSel) = 'array' then do
            val = Tree
            key = null
            for _opt = 1 to TreeSel.Length do
                opt = val[TreeSel[_opt]]
                val = opt[2]
            end
        end
        if UT.IsOpt(val) then DisableItem('Details')
        else EnableItem('Details')
    enditem
    
    button "Details" 30, after, 10, 1.5 resize: top, left disabled do
        UT.ShowValue(val)
    enditem
    button "OK" after, same, 10, 1.5 resize: top, left do
        UT = null
        Return()
    enditem
    
    close do 
        UT = null 
        Return()
    enditem
EndDbox


//******************************************************************************
//** TransitUT Contents:                                                      **
//**  LinkRouteSys: Link, reload, and verify a route system                   **
//**  WalkAccess: Add walk access links to a network                          **
//**  SelectRouteLinks: Select all links used by routes in a route system     **
//**                                                                          **
//******************************************************************************
Class "TransitUT" //StartClass

//******************************************************************************
// LinkRouteSys: Link a rts and dbd file, with options to reload/verify.
	Macro "LinkRouteSys" (rts_file, tdbd_file, InOpts) do
//     - Reload and verify the route system (can be disabled with options)
//        -> Displays an error message if a problem is found
//     - Check that all route stops are associated with a node in the line layer
//        -> Maps problem nodes if any are found
//

	// *****************************************************************************
	// Input:
	//   rts_file: Route system to be linked
	//   tdbd_file: Line layer to use for route system
	//
	// Options:
	//  - .Silent
	//     --> True: no messages will be shown unless an error occurs.
	//     --> True: then the macro will not check to see if the route system
	//               uses links that are not enabled.
	//  - .Reload
	//     --> True: don't re-load the route system
	//  - .Verify
	//     --> True: Don't verify the route system
    //  - TagStops
    //     --> True: Tag stops to nodes
	//  - .StopField: Name of field to tag stops (Defaults to NodeID)
    //  - .StopBuffer: Stop tag buffer (Defaults to 0.1)
	//  - .OpenMap: Leave the map open instead of closing it
	// *****************************************************************************

		shared scen_ui

		tag_buffer = 0.2  //Buffer used when tagging stops to nodes

	NextStep = "Set Route System Line Layer"
	SetStatus(1, NextStep, )

		//Verify that the stops layer was not selected as the line layer

		file_err = "False"
 		rts_split = SplitPath(rts_file)
		rts_split = rts_split[3] + "S.dbd"
		tdbd_split= SplitPath(tdbd_file)
		tdbd_split = tdbd_split[3] + tdbd_split[4]
		if rts_split = tdbd_split then file_err = "True"
		else do
			tmp = GetDbLayers(tdbd_file)
			if tmp.Length <> 2 then file_err = "True"
		end

		if file_err = "True" then do
			ShowMessage("Invalid File Selection: Cannot link route system to selected geographic file!")
			Return()
		end

		Layers = GetDBLayers(tdbd_file)
		{node_lyr, link_lyr} = Layers
		ModifyRouteSystem(rts_file, {{"Geography", tdbd_file, link_lyr}, {"Route ID", "ID"}})

	NextStep = "Load the Route System"
	SetStatus(1, NextStep, )

		tdbd_info = GetDBInfo(tdbd_file)
    	map_name = CreateMap("Route System", {{"Scope", tdbd_info[1]},{"Auto Project", "True"}})
    	lyrs = AddRouteSystemLayer(map_name, "Route System", rts_file,)
    	RunMacro("Set Default RS Style", lyrs, "TRUE", "TRUE")
    	route_lyr = lyrs[1]
    	stop_lyr  = lyrs[2]

	NextStep = "Reload the Route System"
	SetStatus(1, NextStep, )

		if InOpts.Reload then ReloadRouteSystem(rts_file)

	NextStep = "Verify Route System"
	SetStatus(1, NextStep, )

		if InOpts.Verify then do

			VerifyRouteSystem(rts_file, )

			on Error do
				ShowMessage("Route System Verification: One or more routes is disconnected.\n\n" +
		            		"See the TransCAD Log File for details. (Edit: Preferences, Logging)")
				goto quit
			end
			VerifyRouteSystem(rts_file, "Connected")
			on Error default
		end

	NextStep = "Tag Stops to Nodes"
	SetStatus(1, NextStep, )

		if InOpts.TagStops then do
            sfield = if InOpts.StopField = null then "NodeID" else InOpts.StopField
            tag_buffer = if InOpts.StopBuffer = null then "NodeID" else InOpts.StopBuffer

			stop_cnt = GetRecordCount(stop_lyr, )
			SetDataVector(stop_lyr+"|", sfield, Vector(stop_cnt, "Long", ), )
			missed = TagRouteStopsWithNode(route_lyr, , sfield, tag_buffer)

            //Checking for blank stop IDs and crashing if a problem is found
            // (even when running in Silent mode, since this will cause a
            //  crash later anyway)

            if missed > 0 then do
                ShowMessage("Route System Verification: " + string(missed) + " Stops are not adjacent to a node on the associated route.\n\n" +
                            "See the selection set \"Invalid Stops\" for details.")
                SetLayer(stop_lyr)
                SelectByQuery("Invalid Stops", "Several", "Select * Where [" + sfield + "] = null", )
                colors = RunMacro("G30 setup colors")
                SetIcon(stop_lyr+"|Invalid Stops", "Font Character", "Caliper Cartographic|14", 38)
                SetIconColor(stop_lyr+"|Invalid Stops", colors[5])
                SetDisplayStatus(stop_lyr+"|Invalid Stops", "Active")

                Return()  //Return without closing the map
            end

		end //end if !NoStops

		//Exit the macro if running in silent mode...
		if InOpts.Silent then do
			if !InOpts.OpenMap then CloseMap(map_name)
			SetStatus(1, "@System0", )
			Return(1)
		end

	NextStep = "Verify Link Status"
	SetStatus(1, NextStep, )

		//Ask if the link status should be checked
		Opts = null
		Opts.Caption = "Check Links?"
		Opts.Buttons = "YesNo"
		Opts.Icon = "Question"
		ans = MessageBox("The Route System is Valid. Check for routes using disabled links?", Opts)
		if ans = "No" then do
			CloseMap(map_name)
			SetStatus(1, "@System0", )
			Return(1)
		end

		//If checking, ask for a network year
		SetAlternateInterface(scen_ui)
	    	Opts = null
			Opts.HideNetwork = False
			Opts.HideData = True
			year_ans = RunDbox("Set Years", null, null, tdbd_file, null, null, Opts)
		SetAlternateInterface()
		if year_ans = null then do
			CloseMap(map_name)
			SetStatus(1, "@System0", )
			Return(1)
        end
        
		NetYear = year_ans[1]

		//Create a progress bar
		CreateProgressBar("Checking for disabled links", "False")
		
		//Identify routes in the system
		route_names = GetRouteNames(route_lyr)
		route_links = null
		for i = 1 to route_names.length do
			UpdateProgressBar("Searching for links", R2I(i/route_names.length * 100))
			tmp = GetRouteLinks(route_layer, route_names[i])
			route_links = route_links + CopyArray(tmp)
			tmp = null
		end

		//Separate IDs from returned info and
		//remove duplicates
		dim link_ids[route_links.length]
		for i = 1 to link_ids.length do
			UpdateProgressBar("Sort links", R2I(i/link_ids.length * 100))
			link_ids[i] = route_links[i][1]
		end

		
		UpdateProgressBar("Checking links", 33)
		
		link_ids = VectorToArray(SortVector(ArrayToVector(link_ids), {{"Unique", "True"}}))

		//Select route links
		SetLayer(link_lyr)
		link_cnt = SelectByIDs("RouteLinks", "Several", link_ids, )
		
		UpdateProgressBar("Checking links", 66)

		//Select route links where FT is null
		qry = "Select * where FT_"+NetYear+" = null"
		Opts = null
		Opts.[Source And] = "RouteLinks"
		cnt = SelectByQuery("Disabled Links", "Several", qry, Opts)
		
		DestroyProgressBar()

		if cnt > 0 then do
			g30_colors = RunMacro("G30 setup colors")
			SetDisplayStatus(link_lyr+"|Disabled Links", "Active")
			SetLineColor(link_lyr+"|Disabled Links", g30_colors[23])
			SetLineWidth(link_lyr+"|Disabled Links", 8)
			ShowMessage("Error.  The route system uses one or more disabled links in the selected year.  See selection set \"Disabled Links\"")
			SetStatus(1, "@System0", )
			Return()
		end
		else do
			ShowMessage("No Problem Links Found.")
			Return()
		end

		quit:
		if !InOpts.OpenMap then CloseMap(map_name)

	SetStatus(1, "@System0", )

		Return()
	EndItem
	//EndMethod

//******************************************************************************
//  WalkAccess: Creates walk access links
	Macro "WalkAccess" (tdbd_file, rts_file, buffer, max_count, InOpts) do

	//******************************************************************************
	//   --> tdbd_file: Transit dbd file to receive walk links
	//   --> rts_file: File to use for walk link creation (identify stop nodes)
	//   --> buffer: Maximum walk link distance
	//   --> max_count: maximum number of walk links per TAZ
	//
	//   --> Opts.NearNode = "FieldName" //Name of field use to tag stops to nodes
	//
	//   --> Opts.AddFields = Options to add data to the walk links, If one AddFields option
	//                        is specified, ALL must be specified and of the same length.
	//   --> Opts.AddFields.Fields    = {Field1, Field2, ...} //Fields to fill and merge with existing dbd file
	//   --> Opts.AddFields.Type      = {"Real", "Integer", ...}  //Type of new fields
	//   --> Opts.AddFields.Method    = {"Formula/Value", "Formula/Value", ...}   //Method to fill fields referenced above
	//   --> Opts.AddFields.Parameter = {x, x, ...}  //formula or value to fill field
	//******************************************************************************

	shared UT  //Required for utilities called by this macro

	/*	shared canned, debug, ret_value
		//Set up error handlers
		if debug <> 1 then do
			on Escape do
				on Escape default
				canned = "True"
				Return()
			end
			on Error, NotFound, NonUnique, Missing, DivideByZero, EndOfFile, LanguageError do
				on Error, NotFound, NonUnique, Missing, DivideByZero, EndOfFile, LanguageError default
				ShowMessage(GetLastError({{"Reference Info", "True"}}))
				Return()
			end
		end //end definition of error handlers
		*/
		//Define temporary walk access dbd file
		wdbd_file = GetTempFilename(".dbd")

		//Identify stop near node field
		stop_nearnode = InOpts.NearNode

		//Open the dbd file
		RunMacro("TCB Add DB Layers", tdbd_file,,)
		Lyrs = RunMacro("TCB get DB line and node layers", tdbd_file)
		tnode_lyr = Lyrs[1]
		tlink_lyr = Lyrs[2]

		//Identify Transit Stop Nodes
		tmp = SplitPath(rts_file)
		stop_tfile = tmp[1]+tmp[2]+tmp[3]+"S.bin"
		stop_vw = OpenTable("TransitStops", "FFB", {stop_tfile, })
		StopNodes = GetDataVector(stop_vw+"|", stop_nearnode, )
		CloseView(stop_vw)

		//Get unique stop-node IDs
		StopNodes = SortVector(StopNodes, {{"Unique", "True"}})
		StopNodes = v2a(StopNodes)

		//Select stop-nodes
		SetView(tnode_lyr)
		SelectByIDs("AllStops", "several", StopNodes)
		AllStops = v2a(GetDataVector(tnode_lyr+"|AllStops", "ID", ))

		//Select TAZs
		SetView(tnode_lyr)
		SetLayer(tnode_lyr)
		SelectByQuery("Centroids", "Several", "Select * Where Zone > 0", )
		C_IDs = GetDataVector(tnode_lyr+"|Centroids", "ID", )

		//Empty array to hold coordinate pairs
		coord_pairs = null
		//id_pairs = null

		//Process each centroid
		CreateProgressBar("Walk Access (compute)", "True")

		//Save links in a CSV file
		csv_file = GetTempFilename(".csv")
		fp = OpenFile(csv_file, "w")
		for I = 1 to C_IDs.length do
		//for I = 1 to 50 do  //Switch to this for quick troubleshooting/testing
			canned = UpdateProgressBar("Locate Walk Access " + string(I) + " / " + string(C_IDs.length), r2i(I / C_IDs.Length * 100) )
			if canned then Return()

			//Identify nearby nodes
			SetLayer(tnode_lyr)
			C_coord = GetPoint(C_IDs[I])
			STOPS_rec = LocateNearestRecords(C_coord, buffer, )

			//Process each node
			stop_count = 0
			for j = 1 to STOPS_rec.length do
				SetRecord(tnode_lyr, STOPS_rec[j])
				STOP_id = rh2id(STOPS_rec[j])

				//Only add connectors to nodes with stops
				//Only add up to a certain number per centroid
					if stop_count <= max_count and ArrayPosition(AllStops, {STOP_id}, ) > 0 then do

					//Get stop coordinate
					SetLayer(tnode_lyr)
					S_coord = GetPoint(STOP_id)

					//Save coordinate pair
					WriteLine(fp, "2, " + string(C_coord.lon) + ", " +
										string(C_coord.lat) + ", " +
										string(S_coord.lon) + ", " +
										string(S_coord.lat) )
					stop_count = stop_count + 1

				end  //end if node is a stop

			end //end loop over nearby stops
		end  //end loop over zones
		CloseFile(fp)
		DestroyProgressBar()

		//Close the original dbd file
		DropLayerFromWorkspace(tlink_lyr)
		DropLayerFromWorkspace(tnode_lyr)

		//Import the CSV file to a geographic file
		Opts = null
		Opts.Dir = null
		Opts.Geography = 1
		Opts.ID = null
		Opts.Label = "Imported"
		Opts.[Layer Name] = "Imported"
		ImportCSV(csv_file, wdbd_file, "Line", Opts)

		//Open the new dbd file
		RunMacro("TCB Add DB Layers", wdbd_file,,)
		Lyrs = RunMacro("TCB get DB line and node layers", wdbd_file)
		wnode_lyr = Lyrs[1]
		wlink_lyr = Lyrs[2]

		//check to see if fields should be added, filled, and merged
		if InOpts.AddFields <> null then do

			//Add fields
			//Fields = {{"FT", "Integer"}, {"MODE", "Integer"}}
			dim Fields[InOpts.AddFields.Fields.Length]
			for i = 1 to Fields.length do
				Fields[i] = {InOpts.AddFields.Fields[i], InOpts.AddFields.Type[i]}
			end

			UT.AddViewFields(Fields, wlink_lyr)

			//Fill FT and MODE fields
            
            /* !!! TC 6 is crashing here
			Opts = null
			Opts.Input.[Dataview Set] = {wdbd_file + "|" + wlink_lyr, wlink_lyr}
			Opts.Global.Fields = InOpts.AddFields.Fields
			Opts.Global.Method = InOpts.AddFields.Method
			Opts.Global.Parameter = InOpts.AddFields.Parameter

			if !RunMacro("TCB Run Operation", "Fill Dataview", Opts) then Return()
            
            */
            cnt = GetRecordCount(wlink_lyr, )
            dim Vs[InOpts.AddFields.Fields.Length]
            for i = 1 to Vs.Length do
                Vs[i] = {InOpts.AddFields.Fields[i], 
                         Vector(cnt, "Double", {{"Constant", InOpts.AddFields.Parameter[i]}})}
            end
            SetDataVectors(wlink_lyr+"|", Vs, )

		end

		//Re-Open the geographic network
		RunMacro("TCB Add DB Layers", tdbd_file,,)
		Lyrs = RunMacro("TCB get DB line and node layers", tdbd_file)
		tnode_lyr = Lyrs[1]
		tlink_lyr = Lyrs[2]

		//Merge the walk links with the main database
		Opts = null
		Opts.Snap = True
		if InOpts.AddFields <> null then do
			for i = 1 to InOpts.AddFields.Fields.length do
				Opts.Fields = Opts.Fields + {{InOpts.AddFields.Fields[i], InOpts.AddFields.Fields[i]}}
			end
		end
		MergeGeography(tlink_lyr, wlink_lyr, Opts)


		//Close the layers
		DropLayerFromWorkspace(wlink_lyr)
		DropLayerFromWorkspace(wnode_lyr)
		DropLayerFromWorkspace(tlink_lyr)
		DropLayerFromWorkspace(tnode_lyr)

		//Delete the temporary walk access dbd file
		DeleteDatabase(wdbd_file)

		//Repair the database now that walk links have been added
		OptimizeDatabase(tdbd_file, )

		Return(1)

	EndItem //End WalkAccess
	//EndMethod

//******************************************************************************
//  SelectRouteLinks: Selects links used by any route in a route system
	Macro "SelectRouteLinks" (route_lyr, tlink_lyr, set_name) do

	//******************************************************************************
	//   --> route_lyr: route system layer
	//   --> tlink_lyr: Matched link layer from which to select links
	//   --> set_name: Name of selection set to create
	//
	//   Returns: integer value: number of links selected (0 if none selected)
	//
	//  * If the user cancels, canned will be set to True and null will be returned
	//
	//******************************************************************************

		shared canned
		//Identify routes in the system
		route_names = GetRouteNames(route_lyr)
		dim route_links[route_names.length]
		CreateProgressBar("Locating Route Links...", "True")
		for i = 1 to route_names.length do
			canned = UpdateProgressBar("Locating Route Links...", r2i(i/route_names.length*100))
			if canned then return()
			tmp = GetRouteLinks(route_lyr, route_names[i])
			route_links[i] = CopyArray(tmp)
			tmp = null
		end
		DestroyProgressBar()

		//Create single empty array link_arr to hold all route link IDs
		link_cnt = 0
		for i = 1 to route_links.length do
			link_cnt = link_cnt + route_links[i].length
		end
		dim link_arr[link_cnt]

		//Collect link IDs from each route and place in link_arr
		k = 1
		for i = 1 to route_links.length do
			for j = 1 to route_links[i].length do
				link_arr[k] = route_links[i][j][1] //item 1 is the ID
				k = k + 1
			end
		end
		//remove duplicates
		link_arr = VectorToArray(SortVector(ArrayToVector(link_arr), {{"Unique", "True"}}))

		//Select links used by the route system
		prev_lyr = GetLayer()
		SetLayer(tlink_lyr)
		link_cnt = SelectByIDs(set_name, "Several", link_arr, )

		//Return to original selected layer
		if prev_lyr <> null then SetLayer(prev_lyr)

		return(link_cnt)

	EndItem //SelectRouteLinks
	//EndMethod

EndClass //End of "TransitUT"

//**************************************************************************
//** More resilient log/report file management
Class "LogManager"  //StartClass
//When created this object will obtain the current log/report filename.  It will reset them
//  when the object is destroyed (obj=null) or goes out of scope.  This means that the log
//  and report filenames will be reset in cases where an error prevents conventional reset
//  lines from being run.

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


Class "FileGrid" (FileOpts, InOpts) //StartClass
    init do
    
        //Pointer reference to original Opts array
        self.FileOpts = FileOpts
        self.DefaultOpts = CopyArray(FileOpts)
    
        //Basic grid settings
		dim grid_cols[3]
        self.grid_cols = grid_cols
	
        self.grid_cols[1].Name = "ID"
        self.grid_cols[1].Width = 25
        self.grid_cols[1].Alignment = "Left"
		self.grid_cols[1].[Read Only] = True
		
		self.grid_cols[2].Name = "File Name"
		self.grid_cols[2].Width = 66.5
		self.grid_cols[2].Alignment = "Right"
		self.grid_cols[2].[Read Only] = True
		
		self.grid_cols[3].Name = "Status"
		self.grid_cols[3].Width = 19.5
		self.grid_cols[3].Alignment = "Left"
		self.grid_cols[3].[Read Only] = True
        
        //Grid colors
        self.Colors = null
		self.Colors.red  = {{"Background Color", ColorRGB(64000,40960,40960)}}     //Red
		self.Colors.green = {{"Background Color", ColorRGB(49407,56575,49407)}}    //Green
		self.Colors.orange = {{"Background Color", ColorRGB(64800,50300,35000)}}   //Orange
		self.Colors.blue = {{"Background Color", ColorRGB(37265,53713,57054)}}     //Blue 
		self.Colors.yellow = {{"Background Color", ColorRGB(64250,59650,29500)}}   //Yellow
        
        //FileList for grid: {{FileKey, FileName, FileStatus}
        dim FL[FileOpts.length]
        for ii = 1 to FileOpts.length do
            dim t[3,2]
            FL[ii] =CopyArray(t) //each line has 3 columns, each column is value, style
        end
        self.FileList = FL
        
        self.UpdateGrid()
        
    
    enditem
    
    Macro "Click" (cell_idx, cell_chg) do
    
	if cell_chg = 1 then do   //If the user double-clicked
		_file = cell_idx[1]   
		file = self.FileList[_file][2][1]
        key = self.FileList[_file][1][1]
		tmp = SplitPath(file) 
		
		// Choose New File
		on escape do goto cancel end
		new_file = ChooseFileName( {{"File", "*" + tmp[4]}}, "Choose Input File",  {{"Initial Directory",   tmp[1]+tmp[2]},
																					{"Suggested Name",      tmp[3]+tmp[4]},
																					{"Replace Warning",         "False"}}) 
		on escape default
			
		if new_file != null then do
			self.FileOpts.(key) = new_file
        end
        
        self.UpdateGrid()
		
	end
	cancel:
    
    enditem //EndMethod
    
    Macro "UpdateGrid" do
    
        for ii = 1 to self.FileList.length do
        
            key = self.FileOpts[ii][1]
            file = self.FileOpts.(key)
            
            if GetFileInfo(file) = null then do 
                use_color = self.Colors.red
                stat = "<Missing>"
            end else if file != self.DefaultOpts.(key) then do
                use_color = self.Colors.blue
                stat = "<Exists>"
            end else do
                use_color = self.Colors.green
                stat = "<Exists>"
            end
            
            //Update filename & Status
            self.FileList[ii][1][1] = key
            self.FileList[ii][2][1] = file
            self.FileList[ii][3][1] = stat
            
            //Update colors
            for jj = 1 to self.FileList[ii].length do
                self.FileList[ii][jj][2] = use_color
            end
        
        end
    
    enditem //EndMethod

EndClass

//EOF