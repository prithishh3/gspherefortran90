module corrfunc
! Correlation functions and related coefficients:
!
! SGSCFSTD: standard deviations for the spherical harmonics coefficients
! CSELL   : correlation length and angle, derivatives
! CSLEGP  : Legendre expansion of the correlation function
! CS1CF   : power law correlation function
! CS2CF   : modified Gaussian correlation function
! CS3CF   : input correlation function coefficients from file
!
! Required modules:
!
use specfunc    ! Special functions.

contains

subroutine SGSCFSTD(SCFSTD,CSCF,beta,lmin,lmax)

! Generates the standard deviations for the spherical harmonics 
! coefficients of the logarithmic radial distance. Version 2002-12-16.
!
! Copyright (C) 2002 Karri Muinonen

implicit none
integer,intent(in) :: lmin,lmax
real(8),intent(in) :: beta
real(8),intent(in),allocatable :: CSCF(:)
real(8),intent(inout),allocatable :: SCFSTD(:,:)
integer :: l,m

if(.not. (allocated(CSCF) .or. allocated(SCFSTD))) stop &
 'trouble in SGSFSTD: Array not allocated.'

if (lmin.eq.0) then
 SCFSTD(0,0)=beta*sqrt(CSCF(0))
 do l=1,lmax
  SCFSTD(l,0)=beta*sqrt(CSCF(l))
  do m=1,l
   SCFSTD(l,m)=SCFSTD(l,0)* &
   sqrt(2.0d0*FACTI(l-m)/FACTI(l+m))
  end do
 end do
else
 do l=lmin,lmax
  SCFSTD(l,0)=beta*sqrt(CSCF(l))
  do m=1,l
   SCFSTD(l,m)=SCFSTD(l,0)* &
   sqrt(2.0d0*FACTI(l-m)/FACTI(l+m))
  end do
 end do
endif
end subroutine SGSCFSTD



subroutine CSELL(CSCF,gam,ell,cs2d,cs4d,lmin,lmax)

! Computes the correlation angle and length, and second and fourth 
! derivatives for a correlation function expressed in Legendre series with
! normalized coefficients. Version 2002-12-16.
!
! Copyright (C) 2002 Karri Muinonen

implicit none
integer,intent(in) :: lmin,lmax
real(8),intent(in),allocatable :: CSCF(:)
real(8),intent(inout) :: gam,ell,cs2d,cs4d
integer :: l

cs2d=0.0d0
cs4d=0.0d0
do l=lmin,lmax
 cs2d=cs2d-CSCF(l)*l*(l+1.0d0)/2.0d0
 cs4d=cs4d+CSCF(l)*l*(l+1.0d0)*(3.0d0*l**2+3.0d0*l-2.0d0)/8.0d0
end do
if (cs2d.eq.0.0d0) then
 ell=2.0d0
else
 ell=1.0d0/sqrt(-cs2d)
endif
gam=2.0d0*asin(0.5d0*ell)
end subroutine CSELL



real(8) function CSLEGP(CSCF,xi,lmin,lmax)

! Computes the Legendre series expansion for the 
! correlation function. Version 2002-12-16.
!
! Copyright (C) 2002 Karri Muinonen

implicit none
integer,intent(in) :: lmin,lmax
real(8),intent(in),allocatable :: CSCF(:)
real(8) :: xi
real(8),allocatable :: LEGP(:,:)
integer :: l

allocate(LEGP(0:lmax,0:lmax))

call LEGAA(LEGP,xi,lmax,0)
LEGP(0,0)=1.0d0

CSLEGP=0.0d0
do l=lmin,lmax
 CSLEGP=CSLEGP+LEGP(l,0)*CSCF(l)
end do
end function CSLEGP



subroutine CS1CF(CSCF,nu,lmin,lmax)

! Returns the Legendre coefficients for the correlation 
! function with power-law Legendre coefficients. Version 2002-12-16.
!
! Copyright (C) 2002 Karri Muinonen

implicit none
integer,intent(in) :: lmin,lmax
real(8),intent(in) :: nu
real(8),intent(inout),allocatable :: CSCF(:)
integer :: l
real(8) :: norm

do l=0,lmin-1
 CSCF(l)=0.0d0
end do

norm=0.0d0
do l=lmin,lmax
 CSCF(l)=1.0d0/l**nu
 norm=norm+CSCF(l)
end do

do l=lmin,lmax
 CSCF(l)=CSCF(l)/norm
end do
end subroutine CS1CF



subroutine CS2CF(CSCF,ell,lmin,lmax)

! Returns the Legendre coefficients for the modified Gaussian correlation 
! function. Version 2002-12-16.
!
! Copyright (C) 2002 Karri Muinonen

implicit none
integer,intent(in) :: lmin,lmax
real(8),intent(in) :: ell
real(8),intent(inout),allocatable :: CSCF(:)
integer :: l
real(8) :: z,norm
real(8),allocatable :: BESISE(:)

allocate(BESISE(0:lmax))

z=1.0d0/ell**2
call BESMSA(BESISE,z,lmax)

do l=0,lmin-1
 CSCF(l)=0.0d0
end do

norm=0.0d0
do l=lmin,lmax
 CSCF(l)=(2*l+1)*BESISE(l)
 norm=norm+CSCF(l)
end do

do l=lmin,lmax
 CSCF(l)=CSCF(l)/norm
end do
end subroutine CS2CF



subroutine CS3CF(CSCF,lmin,lmax)

! Inputs Legendre coefficients for the correlation 
! function from a file (and normalizes). Version 2002-12-16.
!
! Copyright (C) 2002 Karri Muinonen

implicit none
integer,intent(in) :: lmin, lmax
real(8),intent(inout),allocatable :: CSCF(:)
integer :: l,ll
real(8) :: norm

open(unit=1, file='cscf.dat', status='old')

do l=0,lmin-1
 CSCF(l)=0.0d0
end do

norm=0.0d0
do l=lmin,lmax
 read (1,*) ll,CSCF(l) 
 if (l.ne.ll) stop &
 'Trouble in CS3CF: degree inconsistency.'
 if (CSCF(ll).lt.0.0d0) stop &
 'Trouble in CS3CF: negative Legendre coefficient.'
 norm=norm+CSCF(l)
end do
close(unit=1)

if (norm.eq.0.0d0) stop &
'Trouble in CS3CF: no nonzero Legendre coefficients.'

do l=lmin,lmax
 CSCF(l)=CSCF(l)/norm
end do
end subroutine CS3CF
end module corrfunc


