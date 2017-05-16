
program GSPHERE

! GSPHERE generates sample Gaussian spheres. Version 2003-12-10.
!
!
! Free software license 
!
! Siris is free software for the generation of sample Gaussian spheres
! and for the computation of light scattering by Gaussian particles and
! arbitrary polyhedral particles in the ray optics approximation. It is
! available under the GNU General Public License that you can find on
! the World Wide Web (http://www.gnu.org/licenses/gpl.txt) and in the
! file Siris/GPL/gpl.txt.
!
! Contact addresses for Siris Authors:
!
! Karri Muinonen
! Observatory, University of Helsinki
! Kopernikuksentie 1, P.O. Box 14
! FIN-00014 U. Helsinki
! Finland
! E-mail: Karri.Muinonen@helsinki.fi
!
! Timo Nousiainen
! Department of Atmospheric Sciences
! University of Illinois
! 105 S Gregory Street, MC223
! Urbana, IL 61801
! U.S.A.
! E-mail: tpnousia@atmos.uiuc.edu
!
! Siris, Copyright (C) 2003 by the Siris Authors Karri Muinonen
! and Timo Nousiainen. 
!
! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Publi! License as published by
! the Free Software Foundation; either version 2 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Publi! License for more details.
!
! You should have received a copy of the GNU General Publi! License
! along with this program; if not, write to the Free Software
! Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

! Included library subroutine and function packages:
!
!       include 'lib/discrets.f90'! Discretization.
!       include 'lib/gsg.f90'     ! G-sphere generator.
!       include 'lib/gsaxg.f90'   ! Axisymmetri! G-sphere generator.
!       include 'lib/corrfunc.f90'! Correlation functions.
!       include 'lib/voper.f90'   ! Vector rotations and product.
!       include 'lib/specfunc.f90'! Special functions.
!       include 'lib/randev.f90'  ! Random deviates.
       use corrfunc			! Correlation functions.
       use discrets			! Discretization.
       use gsaxg			! Axisymmetric G-sphere generator.
       use gsg				! G-sphere generator.
       use randev			! Random deviates.
       use specfunc			! Special functions.
       use voper			! Vector operations.
       
       implicit none
       integer :: nss,lmin,lmax, &
       j0,j1,j2,gflg,dflg,cflg

       integer :: IT(260000,3),nthe,nphi,ntr,nnod,ntri
       double precision :: XS(0:180,0:360,3), &
        MUS(0:180),PHIS(0:360)
       double precision :: XT(130000,3),NT(260000,3), &
        MUT(130000),PHIT(130000)

       double precision :: ACF(0:256,0:256),BCF(0:256,0:256), &
        SCFSTD(0:256,0:256),CSCF(0:256), &
         EU(3),CEU(3),SEU(3),RGS,RGSAX,a,sig,beta,gami,elli, &
          gam,nuc,ell,cs2d,cs4d,the,mu,grid,rmax,pi,rd
       character ca*2

       integer :: irnd
       double precision :: RNDU
       common irnd

! Initializations:

       pi=4.0d0*atan(1.0d0)
       rd=pi/180.0d0

       irnd=1
       irnd=4*irnd+1
       a=RNDU(irnd)

! Input parameters from option file:

       open(unit=1, file='gsphere.in', status='old')

       a=1.0d0
       read (1,30) ca
       read (1,20) gflg ! General (1) or axisymmetri! spheres (2).
       read (1,20) dflg ! Spherical-coord. (1) or triangle (2) discretization.
       read (1,20) cflg ! Cor. function (C_1=power law, C_2=Gauss, C_3=file).
       read (1,10) sig  ! Relative standard deviation of radial distance.
       read (1,10) nuc  ! Power law index for C_1 correlation.
       read (1,10) gami ! Input angle for C_2 correlation.
       read (1,20) lmin ! Minimum degree in C_1, C_2, C_3.
       read (1,20) lmax ! Maximum degree in C_1, C_2, C_3.
       read (1,20) nthe ! Discretization: number of polar angles.
       read (1,20) nphi ! Discretization: number of azimuths.
       read (1,20) ntr  ! Discretization: number of triangle rows per octant.
       read (1,20) nss  ! Sphere identification number.
10     format (E12.6)
20     format (I12)
30     format (/A2/)
       close(unit=1)

! Input check:

       if (gflg.ne.1 .and. gflg.ne.2) stop &
        'Trouble in GSPHERE: general or axisymmetri! spheres.'
       if (dflg.ne.1 .and. dflg.ne.2) stop &
        'Trouble in GSPHERE: spherical or triangle discretization.'
       if (cflg.ne.1 .and. cflg.ne.2 .and. cflg.ne.3) stop &
        'Trouble in GSPHERE: correlation function unknown.'

       if (sig.le.0.0d0) stop &
        'Trouble in GSPHERE: standard deviation .le. 0.'

       if (cflg.eq.2) then
        if (gami.le.0.0d0 .or. gami.gt.180.0d0) stop &
         'Trouble in GSPHERE: input angle .le. 0. .or.  .gt. 180'
        if (lmin.gt.0 .or. lmax.lt.int(300.0d0/gami)) then
         print*,'Warning in GSPHERE: correlation angle will differ '
         print*,'from input value. Set minimum degree to 0 and '
         print*,'maximum degree .gt. (300 deg)/(input value).'
        endif
       endif

       if (lmax.gt.256) stop &
        'Trouble in GSPHERE: maximum degree .gt. 256.'
       if (lmin.lt.0) stop &
        'Trouble in GSPHERE: minimum degree .lt. 0.'
       if (lmin.gt.lmax) stop &
        'Trouble in GSPHERE: minimum degree .lt. maximum degree.'
       if (cflg.eq.1 .and. lmin.lt.2) stop &
        'Trouble in GSPHERE: minimum degree .lt.2.'

       if (nthe.gt.180) stop &
        'Trouble in GSPHERE: number of polar angles .gt.180.'
       if (nphi.gt.360) stop &
        'Trouble in GSPHERE: number of azimuths .gt.360.'
       if (ntr.gt.180) stop &
        'Trouble in GSPHERE: number of triangle rows .gt.180.'

       if (nss.le.0) stop &
        'Trouble in GSPHERE: sphere identification number .lt. 0.'

! Miscellaneous:

       gami=gami*rd
       elli=2.0d0*sin(0.5d0*gami)

! Initialization of the Gaussian random sphere:

       beta=sqrt(log(sig**2+1.0d0))
       if     (cflg.eq.1) then
        call CS1CF(CSCF,nuc,lmin,lmax)
       elseif (cflg.eq.2) then
        call CS2CF(CSCF,elli,lmin,lmax)
       elseif (cflg.eq.3) then
        call CS3CF(CSCF,lmin,lmax)
       endif

       do 40 j1=lmin,lmax
        if (CSCF(j1).lt.0.0d0) stop &
         'Trouble in GSPHERE: negative Legendre coefficient.'
40     end do

       call SGSCFSTD(SCFSTD,CSCF,beta,lmin,lmax)

! Generate a sample Gaussian sphere with identification number
! nss, then move to discretize and output:

       do 100 j0=1,nss
        if (gflg.eq.1) then
         call SGSCF(ACF,BCF,SCFSTD,lmin,lmax)
        else
         call SGSAXCF(ACF,CEU,SEU,SCFSTD,lmin,lmax)
        endif
100    end do
       
       if (dflg.eq.1) then

! Spherical-coordinate representation for general and axisymmetri! shapes:

        call SPHDS(MUS,PHIS,nthe,nphi)
        if (gflg.eq.1) then
         call RGSSD(XS,MUS,PHIS,ACF,BCF,rmax,beta, &
                   nthe,nphi,lmin,lmax)
        else
         call RGSAXSD(XS,MUS,PHIS,ACF,CEU,SEU,rmax,beta, &
                     nthe,nphi,lmin,lmax)
        endif

        open(unit=1, file='matlabx.out')            ! Matlab
        open(unit=2, file='matlaby.out')
        open(unit=3, file='matlabz.out')
        do 110 j1=0,nthe
         write (1,115) (XS(j1,j2,1),j2=0,nphi)
         write (2,115) (XS(j1,j2,2),j2=0,nphi)
         write (3,115) (XS(j1,j2,3),j2=0,nphi)
110     end do
115     format(500(E14.8,1X))
        close(unit=3)
        close(unit=2)
        close(unit=1)

       else

! Triangle representation for general and axisymmetri! shapes:

        call TRIDS(MUT,PHIT,IT,nnod,ntri,ntr)
        if (gflg.eq.1) then
         call RGSTD(XT,NT,MUT,PHIT,ACF,BCF,rmax,beta, &
     	 IT,nnod,ntri,lmin,lmax)
        else
         call RGSAXTD(XT,NT,MUT,PHIT,ACF,CEU,SEU,rmax,beta, &
                     IT,nnod,ntri,lmin,lmax)
        endif

        open(unit=1, file='matlabx.out')           ! Matlab
        open(unit=2, file='matlaby.out')
        open(unit=3, file='matlabz.out')
        do 120 j2=1,3
         write (1,125) (XT(IT(j1,j2),1),j1=1,ntri)
         write (2,125) (XT(IT(j1,j2),2),j1=1,ntri)
         write (3,125) (XT(IT(j1,j2),3),j1=1,ntri)
120     end do
125     format(130000(E14.8,1X))
        close(unit=3)
        close(unit=2)
        close(unit=1)

        open(unit=1, file='idl.out')               ! IDL
        write (1,*) nnod,ntri
        do 130 j1=1,nnod
         write (1,*) (XT(j1,j2),j2=1,3)
130     end do
        do 140 j1=1,ntri
         write (1,*) 3
         write (1,*) (IT(j1,j2),j2=1,3)
140     end do
        close(unit=1)


        open(unit=1, file='vtk.out')               ! VTK
        write (1,150) '# vtk DataFile Version 2.0'
        write (1,150) 'gsphere output            '
        write (1,150) 'ASCII                     '
        write (1,150) 'DATASET POLYDATA          '
        write (1,160) 'POINTS ',nnod,' float'
150     format(a26)
160     format(a7,I7,A7)
        do 170 j1=1,nnod
         write (1,*) (XT(j1,j2),j2=1,3)
170     end do
        write (1,180) 'POLYGONS ',ntri,4*ntri
180     format(a9,I7,I7)
        do 190 j1=1,ntri
         write (1,*) 3,(IT(j1,j2)-1,j2=1,3)
190     end do
        close(unit=1)
       endif
       end



! Included library subroutine and function packages:
!
!       include 'lib/discrets.f90'! Discretization.
!       include 'lib/gsg.f90'     ! G-sphere generator.
!       include 'lib/gsaxg.f90'   ! Axisymmetri! G-sphere generator.
!       include 'lib/corrfunc.f90'! Correlation functions.
!       include 'lib/voper.f90'   ! Vector rotations and product.
!       include 'lib/specfunc.f90'! Special functions.
!       include 'lib/randev.f90'  ! Random deviates.


