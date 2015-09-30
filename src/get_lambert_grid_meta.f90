!-------------------------------------------------------------------------
! National Center for Atmospheric Research
! Research Applications Laboratory
!-------------------------------------------------------------------------

subroutine get_lambert_grid_meta(len1,fileIn,nx,ny,dx,dy,lat1,lon1,lonv, &
                                 latd,latin1,latin2,snFlag,error)

  !DESCRIPTION:
  ! Subroutine that opens a GRIB file and extracts meta data about
  ! the lambert conformal conic grid contained. Meta data is pulled
  ! based on the first message (variable). This subroutine assumes
  ! all variables in the GRIB file are on the same grid. Arguments are
  ! as follows:
  ! len1 - Length of the character string fileIn. This is needed to properly
  !        read in character strings. 
  ! fileIn - Character string of GRIB file name to be read.
  ! nx - Integer of the number of columns of the GRIB data.
  ! ny - Integer of the number of rows of the GRIB data.
  ! dx - Integer of the resolution in the x-direction (meters) of the GRIB data.
  ! dy - Integer of the resolution in the y-direction (meters) of the GRIB data.
  ! lat1 - FLoat of the lower left pixel cell latitude in degrees of the GRIB data.
  ! lon1 - Float of the lower left pixel cell longitude in degrees of the 
  !        GRIB data.
  ! lonv - Float of the origin longitude of the GRIB data domain. 
  !        Typically the center.
  ! latd - Float of the origin latitude of the GRIB data domain. 
  !        Typically the center. 
  ! latin1 - Float of the first standard parallel latitude of the GRIB data.
  ! latin2 - Float of the second standard parallel latitude of the GRIB data.
  ! snFlag - Integer indicating if data is read south-north or north-south. 
  !          1 - Data read south-north
  !          0 - Data read north-south 
  ! error - Error value out. 0 for success. Greater than 0 for error. 

  !AUTHOR:
  ! Logan Karsten
  ! National Center for Atmospheric Research
  ! Research Applications Laboratory
  ! 303-497-2693
  ! karsten@ucar.edu

  !USES:
  use grib_api

  implicit none
  
  !ARGUMENTS:
  integer, intent(in)         :: len1
  character(len1), intent(in) :: fileIn
  integer, intent(inout)      :: nx, ny, dx, dy
  real*8, intent(inout)       :: lat1, lon1, lonv, latd
  real*8, intent(inout)       :: latin1, latin2
  integer, intent(inout)      :: snFlag
  integer, intent(inout)      :: error

  !LOCAL VARIABLES:
  integer :: iret, ftn, nvars, igrib
  logical :: file_exists
  integer :: radius, gdef
  integer :: edition

  !Inquire for file existence
  inquire(file=trim(fileIn),exist=file_exists)
  
  if(file_exists) then
    !Open GRIB file
    call grib_open_file(ftn,trim(fileIn),'r',iret)
    error = iret
  else
    error = 1
  endif

  !Pull the first message (variable) as we are only interested in grid metadata.
  call grib_count_in_file(ftn,nvars,iret)
  if(nvars .le. 0) then
    error = 2
  else
    !Pull grid metadata from first message
    call grib_new_from_file(ftn,igrib,iret)
    error = iret
 
    !Get GRIB edition number 
    call grib_get(igrib,'editionNumber',edition,iret)

    !Unfortunately, GRIB 1 files do not contain grid definition information for checking. 
    !Proceed with caution....
   
    !Sanity check to double check grid is lambert conformal and has an assumed
    !spherical Earth radius. If not, throw a error back to R for 
    !diagnostics.
    if(edition .eq. 2) then
      call grib_get(igrib,'gridDefinitionTemplateNumber',gdef,iret)
      error = iret
    else
      gdef = 30
      error = 0 !GRIB1 no check
    endif
    if (gdef .ne. 30) then
      error = 30
    else
      if(edition .eq. 2) then
        call grib_get(igrib,'shapeOfTheEarth',radius,iret)
        error = iret
      else
        radius = 6
        error = 0
      endif
      if (radius .ne. 6) then
        error = 6
      endif
    endif

    if (error .eq. 0) then !Extract meta data
      call grib_get(igrib,'latitudeOfFirstGridPointInDegrees',lat1,iret)
      call grib_get(igrib,'longitudeOfFirstGridPointInDegrees',lon1,iret)
      call grib_get(igrib,'LoVInDegrees',lonv,iret)
      call grib_get(igrib,'LaDInDegrees',latd,iret)
      call grib_get(igrib,'Latin1InDegrees',latin1,iret)
      call grib_get(igrib,'Latin2InDegrees',latin2,iret)
      call grib_get(igrib,'DxInMetres',dx,iret)
      call grib_get(igrib,'DyInMetres',dy,iret)
      call grib_get(igrib,'Nx',nx,iret)
      call grib_get(igrib,'Ny',ny,iret)
      call grib_get(igrib,'jScansPositively',snFlag,iret)
      error = iret
    endif
  endif

  !Close GRIB file
  call grib_close_file(ftn,iret)
  error = iret

end subroutine get_lambert_grid_meta
