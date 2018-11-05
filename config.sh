#!/bin/sh
#---------------------------------------------------------------------------------
# variables for unattended script execution
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# Toolchain installation directory, comment if not specified
#---------------------------------------------------------------------------------
#BUILD_DKPRO_INSTALLDIR=/opt/devkitpro
BUILD_DKMINT_INSTALLDIR=`pwd`/devkitMINT
#BUILD_DKMINT_INSTALLDIR=/p/devkitPro

#---------------------------------------------------------------------------------
# Automated script execution
#---------------------------------------------------------------------------------
#  0: Ask to delete build folders & patched sources 
#  1: Use defaults, don't pause for answers 
#---------------------------------------------------------------------------------
BUILD_DKMINT_AUTOMATED=1
