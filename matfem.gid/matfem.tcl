
#################################################
#      GiD-Tcl procedures invoked by GiD        #
#################################################
proc GiD_Event_InitProblemtype { dir } {
    Matfem::SetDir $dir ;#store to use it later
    Matfem::RegisterGiDEvents
    Matfem::ModifyMenus
    GidUtils::OpenWindow CUSTOMLIB
}

proc GiD_Event_EndProblemtype {} {
    GiD_UnRegisterPluginAddedMenuProc Matfem::ModifyMenus
}

#################################################
#      namespace implementing procedures        #
#################################################
namespace eval ::Matfem {

}

#################################################
#                 Write script                  #
#################################################

proc Matfem::WriteCalculationFile {filename} {
    # start writting
    customlib::InitWriteFile $filename

    # Header

    # Material properties

    # Coordinates

    # Connectivities

    # Constraints

    # Loads

    # finish writting
    customlib::EndWriteFile ;
}

#################################################
#              Do not touch below               #
#################################################

proc Matfem::SetDir { dir } {  
    variable problemtype_dir
    set problemtype_dir $dir
}

proc Matfem::GetDir { } {  
    variable problemtype_dir
    return $problemtype_dir
}

proc Matfem::RegisterGiDEvents {} {
    
    # Unregister previous events
    GiD_UnRegisterEvents PROBLEMTYPE Matfem
    
    # Write - Calculation
    GiD_RegisterEvent GiD_Event_AfterWriteCalculationFile Matfem::AfterWriteCalculationFile PROBLEMTYPE Matfem
        
    #register the proc to be automatically called when re-creating all menus (e.g. when doing files new or changing the current language)
    GiD_RegisterPluginAddedMenuProc Matfem::ModifyMenus
}

proc Matfem::AfterWriteCalculationFile { filename errorflag } {   
    if { ![info exists gid_groups_conds::doc] } {
        WarnWin [= "Error: data not OK"]
        return
    }    
    set err [catch { Matfem::WriteCalculationFile $filename } ret]
    if { $err } {       
        WarnWin [= "Error when preparing data for analysis (%s)" $::errorInfo]
        set ret -cancel-
    }
    return $ret
}

proc Matfem::ModifyMenus { } {   
    if { [GidUtils::IsTkDisabled] } {  
        return
    }          
    GiDMenu::UpdateMenus
}


######################################################################
#  auxiliary procs invoked from the tree (see .spd xml description)
proc Matfem::GetMaterialsList { domNode args } {    
    set x_path {//container[@n="materials"]}
    set dom_materials [$domNode selectNodes $x_path]
    if { $dom_materials == "" } {
        error [= "xpath '%s' not found in the spd file" $x_path]
    }
    set image material
    set result [list]
    foreach dom_material [$dom_materials childNodes] {
        set name [$dom_material @name] 
        lappend result [list 0 $name $name $image 1]
    }
    return [join $result ,]
}

proc Matfem::EditDatabaseList { domNode dict boundary_conds args } {
    set has_container ""
    set database materials    
    set title [= "User defined"]      
    set list_name [$domNode @n]    
    set x_path {//container[@n="materials"]}
    set dom_materials [$domNode selectNodes $x_path]
    if { $dom_materials == "" } {
        error [= "xpath '%s' not found in the spd file" $x_path]
    }
    set primary_level material
    if { [dict exists $dict $list_name] } {
        set xps $x_path
        append xps [format_xpath {/blockdata[@n=%s and @name=%s]} $primary_level [dict get $dict $list_name]]
    } else { 
        set xps "" 
    }
    set domNodes [gid_groups_conds::edit_tree_parts_window -accepted_n $primary_level -select_only_one 1 $boundary_conds $title $x_path $xps]          
    set dict ""
    if { [llength $domNodes] } {
        set domNode [lindex $domNodes 0]
        if { [$domNode @n] == $primary_level } {      
            dict set dict $list_name [$domNode @name]
        }
    }
    return [list $dict ""]
}
