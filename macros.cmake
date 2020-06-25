macro(addLibraryWithRPATH NAME)
    SET(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH "@executable_path/Plugins")

    add_library(${NAME} SHARED ${ARGN})
    set_target_properties(${NAME} PROPERTIES MACOSX_RPATH ON)
    set_target_properties(${NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_DIRECTORY})
    set_target_properties(${NAME} PROPERTIES INSTALL_NAME_DIR "@executable_path/Plugins")

    # Declare the main executable depends on the plugin so it gets built with it
    add_dependencies(${VM_EXECUTABLE_NAME} ${NAME})
    #Declare the plugin depends on the VM core library
    if(NOT "${NAME}" STREQUAL "${VM_LIBRARY_NAME}")
        target_link_libraries(${NAME} ${VM_LIBRARY_NAME})
    endif()
endmacro()


macro(get_platform_name VARNAME)
    if(WIN)
        set(${VARNAME} "win")
    else()
        if(OSX)
            set(${VARNAME} "mac")
        else()
            set(${VARNAME} "linux")
        endif()
    endif()
endmacro()

macro(get_full_platform_name VARNAME)

    if(SIZEOF_VOID_P EQUAL 8)
        set(ARCH 64)
    else()
        set(ARCH 32)
    endif()

    if(WIN)
        set(${VARNAME} "win${ARCH}")
    else()
        if(OSX)
            set(${VARNAME} "mac${ARCH}")
        else()
            set(${VARNAME} "linux${ARCH}")
        endif()
    endif()
endmacro()

macro(get_full_platform_name_with_osx VARNAME)

    if(SIZEOF_VOID_P EQUAL 8)
        set(ARCH 64)
    else()
        set(ARCH 32)
    endif()

    if(WIN)
        set(${VARNAME} "win${ARCH}")
    else()
        if(OSX)
            set(${VARNAME} "osx${ARCH}")
        else()
            set(${VARNAME} "linux${ARCH}")
        endif()
    endif()
endmacro()



macro(do_decompress_thirdparty NAME TARGETPATH)
    add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/build/third-party/${NAME}.done"
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/${TARGETPATH}
        COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_CURRENT_BINARY_DIR}/build/third-party unzip -o "${NAME}.zip" -d ${CMAKE_CURRENT_BINARY_DIR}/${TARGETPATH}
        COMMAND ${CMAKE_COMMAND} -E touch "${CMAKE_CURRENT_BINARY_DIR}/build/third-party/${NAME}.done"
        DEPENDS "build/third-party/${NAME}.zip"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

    add_custom_target(${NAME} ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/build/third-party/${NAME}.done")
    add_dependencies(${VM_EXECUTABLE_NAME} ${NAME})
endmacro()

# Add a third party dependency taken from the given URL
macro(add_third_party_dependency_with_baseurl NAME TARGETPATH BASEURL)

    get_platform_name(PLATNAME)
    message("Adding third-party libraries for ${PLATNAME}: ${NAME}")

    add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/build/third-party/${NAME}.zip"
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/build/third-party
        COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_CURRENT_BINARY_DIR}/build/third-party wget --no-check-certificate "${BASEURL}/${NAME}.zip"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

	do_decompress_thirdparty(${NAME} ${TARGETPATH})
endmacro()

# Add a third party dependency taken from the files.pharo.org repository
macro(add_third_party_dependency NAME TARGETPATH)
    get_platform_name(PLATNAME)
    set(BASE_URL "https://files.pharo.org/vm/pharo-spur64/${PLATNAME}/third-party/")
    add_third_party_dependency_with_baseurl(${NAME} ${TARGETPATH} ${BASE_URL})
endmacro()

macro(add_third_party_dependency_from_jenkins LIBNAME TARGETPATH JOB BRANCH VERSION)
    get_full_platform_name_with_osx(PLATNAME)

	set(NAME ${LIBNAME}-${VERSION}-${PLATNAME})
	set(URL "https://ci.inria.fr/pharo-ci-jenkins2/job/${JOB}/job/${BRANCH}/lastSuccessfulBuild/artifact/build/packages/${NAME}.zip")

    message("Adding third-party libraries for ${PLATNAME} from Jenkins: ${NAME} (at ${URL})")
    
    add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/build/third-party/${NAME}.zip"
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/build/third-party
        COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_CURRENT_BINARY_DIR}/build/third-party wget --no-check-certificate "${URL}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

	do_decompress_thirdparty(${NAME} ${TARGETPATH})
endmacro()

macro(get_commit_hash VARNAME)
    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE ${VARNAME}
        OUTPUT_STRIP_TRAILING_WHITESPACE)
endmacro()

macro(get_git_describe VARNAME)
    execute_process(
        COMMAND git describe --always
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE ${VARNAME}
        OUTPUT_STRIP_TRAILING_WHITESPACE)
endmacro()

macro(get_git_date VARNAME)
    execute_process(
        COMMAND git log -1 --format=%ai
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE ${VARNAME}
        OUTPUT_STRIP_TRAILING_WHITESPACE)
endmacro()
