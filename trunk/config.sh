#!/bin/sh
#---------------------------------------------------------------------------------
# variables for unattended script execution
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# Download source packages
#---------------------------------------------------------------------------------
#   0: User selects manually
#   1: already downloaded
#   2: download packages
#---------------------------------------------------------------------------------
BUILD_DKMINT_DOWNLOAD=1

#---------------------------------------------------------------------------------
# Toolchain installation directory, comment if not specified
#---------------------------------------------------------------------------------
#BUILD_DKPRO_INSTALLDIR=/opt/devkitpro
BUILD_DKMINT_INSTALLDIR=`pwd`/devkitMINT
#BUILD_DKMINT_INSTALLDIR=/p/devkitPro

#---------------------------------------------------------------------------------
# Path to previously downloaded source packages, comment if not specified
#---------------------------------------------------------------------------------
BUILD_DKMINT_SRCDIR=`pwd`/sources

#---------------------------------------------------------------------------------
# Automated script execution
#---------------------------------------------------------------------------------
#  0: Ask to delete build folders & patched sources 
#  1: Use defaults, don't pause for answers 
#---------------------------------------------------------------------------------
BUILD_DKMINT_AUTOMATED=0
