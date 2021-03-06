! --------------------------------------------------------------------
!
! Copyright (C) 2015 Rocco Meli
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
! ---------------------------------------------------------------------

MODULE NUCLEAR

    USE FACT
    USE CONSTANTS
    USE GAUSSIAN

    IMPLICIT NONE

    !REAL*8 :: xx
    !INTEGER :: nunu

    CONTAINS
        FUNCTION f(j,l,m,a,b)
            !----------------------------------------
            ! Expansion coefficient.
            !----------------------------------------
            !
            ! Source:
            !     Handbook of Computational Chemistry
            !     David Cook
            !     Oxford University Press
            !     1998
            !
            !----------------------------------------

            ! INPUT
            INTEGER, intent(in) :: j, l, m
            REAL*8, intent(in) :: a, b

            ! INTERMEDIATE VARIABLES
            INTEGER :: k    ! Loop index
            REAl*8 :: tmp   ! Temporary product

            ! OUTPUT
            REAL*8 :: f

            f = 0.0D0

            DO k = MAX(0,j-m), MIN(j,l)
                tmp = 1.0D0
                tmp = tmp * binom(l,k) * binom(m,j-k)
                tmp = tmp * a**(l-k) * b**(m+k-j)

                f = f + tmp
            END DO

        END FUNCTION f

        ! -------------
        ! BOYS FUNCTION
        ! -------------
        FUNCTION boys(nu,x)
            ! ------------------------------------------------------------------------
            ! Compute boys function (different strategies for different x)
            ! ------------------------------------------------------------------------
            !
            ! Source:
            !   On the evaluation of Boys functions using downward  recursion relation
            !   B. A. Mamedov
            !   Journal of Mathematical Chemistry
            !   2004
            !
            ! ------------------------------------------------------------------------

            IMPLICIT NONE

            REAL*8, EXTERNAL :: DGAMIT

            ! INPUT
            INTEGER, intent(in) :: nu   ! Boys' index
            REAL*8, intent(in) :: x

            ! INTERMEDIATE VARIABLES
            !REAL*8 :: prod
            !REAL*8 :: sum
            !REAL*8 :: sumold
            !INTEGER :: idx

            ! OUTPUT
            REAL*8 :: boys

            boys = 0.0D0

            IF (x .LE. 1e-6) THEN   ! First order Taylor expansion of the integrand

                boys = 1.0D0 / (2.0D0 * nu + 1.0D0) - x / (2.0D0 * nu + 3.0D0)

            ELSE

                boys = 0.5D0 * DGAMIT(nu + 0.5D0, x) * GAMMA(nu + 0.5D0)
                
            END IF

        END FUNCTION boys

        FUNCTION A(l,r,i,l1,l2,Ra,Rb,Rc,Rp,eps)
            ! -------------------------------------
            ! Factor A
            ! -------------------------------------
            !
            ! Source:
            !   Handbook of Computational Chemistry
            !   David Cook
            !   Oxford University Press
            !   1998
            !
            !--------------------------------------

            ! INPUT
            INTEGER, intent(in) :: l, r, i , l1, l2
            REAL*8, intent(in) :: Ra, Rb, Rc, Rp, eps

            ! OUTPUT
            REAL*8 :: A

            A = 1.0D0
            A = A * (-1)**(l)
            A = A * f(l,l1,l2,Rp-Ra,Rp-Rb)
            A = A * (-1)**i
            A = A * factorial(l)
            A = A * (Rp-Rc)**(l - 2*r - 2*i)
            A = A * eps**(r+i)
            A = A / factorial(r)
            A = A / factorial(i)
            A = A / factorial(l - 2*r - 2*i)

        END FUNCTION A


        FUNCTION nuclear_coeff(ax,ay,az,bx,by,bz,aa,bb,Ra,Rb,Rn,Zn) result(Vnn)
            ! -------------------------------------------------------------------------
            ! Compute electon-nucleus integral between two Cartesian Gaussian functions
            ! -------------------------------------------------------------------------
            !
            ! Source:
            !   Handbook of Computational Chemistry
            !   David Cook
            !   Oxford University Press
            !   1998
            !
            !--------------------------------------------------------------------------

            ! INPUT
            INTEGER, intent(in) :: ax, ay, az, bx, by, bz   ! Angular momentum coefficients
            REAL*8, intent(in) :: aa, bb                    ! Exponential Gaussian coefficients
            REAL*8, dimension(3), intent(in) :: Ra, Rb      ! Gaussian centers
            REAL*8, dimension(3), intent(in) :: Rn          ! Nuclear position
            INTEGER, intent(in) :: Zn                       ! Nuclear charge

            ! INTERMEDIATE VARIABLES
            REAL*8 :: eps
            REAL*8 :: g                             ! Gaussian produc exponential coefficient
            REAL*8, dimension(3) :: Rp              ! Gaussian produc center
            REAL*8 :: cp                            ! Gaussian product multiplicative constant
            INTEGER :: l, r, i, m, s, j, n, t, k    ! Loop indices
            REAL*8 :: AAx, AAy, AAz                 ! Temporary calls to FUNCTION A
            INTEGER :: nu                           ! Boys function index

            ! OUTPUT
            REAL*8 :: Vnn ! Nuclear matrix element

            CALL gaussian_product(aa,bb,Ra,Rb,g,Rp,cp)

            eps = 1.0D0 / (4.0D0 * g)

            Vnn = 0.0D0

            DO l = 0, ax+bx
                DO r = 0, FLOOR(l / 2.0)
                    DO i = 0, FLOOR((l - 2*r)/2.0)
                        AAx = A(l,r,i,ax,bx,Ra(1),Rb(1),Rn(1),Rp(1),eps)

                        DO m = 0, ay+by
                            DO s = 0, FLOOR(m / 2.0)
                                DO j = 0, FLOOR((m - 2*s)/2.0)
                                    AAy = A(m,s,j,ay,by,Ra(2),Rb(2),Rn(2),Rp(2),eps)

                                    DO n = 0, az+bz
                                        DO t = 0, FLOOR(n / 2.0)
                                            DO k = 0, FLOOR((n - 2*t)/2.0)
                                                AAz =  A(n,t,k,az,bz,Ra(3),Rb(3),Rn(3),Rp(3),eps)

                                                nu = l + m + n - 2 * (r + s + t) - (i + j + k)

                                                Vnn = Vnn + AAx * AAy * AAz * boys(nu,g*DOT_PRODUCT(Rp-Rn,Rp-Rn))

                                            END DO ! k
                                        END DO ! t
                                    END DO ! n
                                END DO ! j
                            END DO ! s
                        END DO ! m
                    END DO ! i
                END DO ! r
            END DO ! l

            Vnn = Vnn * (-Zn) * norm(ax,ay,az,aa) * norm(bx,by,bz,bb) * cp * 2.0D0 * PI / g

        END FUNCTION nuclear_coeff


        ! --------------------------------
        ! NUCLEUS-ELECRON POTENTIAL MATRIX
        ! --------------------------------
        SUBROUTINE V_nuclear(Kf,c,basis_D,basis_A,basis_L,basis_R,Vn,Rnn,Znn)
            ! ------------------------------------------
            ! Compute nucleus-electrona potential matrix
            ! ------------------------------------------

            IMPLICIT NONE

            ! INPUT
            INTEGER, intent(in) :: Kf                       ! Number of basis functions
            INTEGER, intent(in) :: c                        ! Number of contractions (TODO)
            REAL*8, dimension(Kf,3), intent(in) :: basis_R  ! Basis set niclear positions
            INTEGER, dimension(Kf,3), intent(in) :: basis_L ! Basis set angular momenta
            REAL*8, dimension(Kf,c), intent(in) :: basis_D  ! Basis set contraction coefficients
            REAL*8, dimension(Kf,c), intent(in) :: basis_A  ! Basis set exponential contraction coefficients
            REAL*8, dimension(3), intent(in) :: Rnn         ! Nuclear position
            INTEGER, intent(in) :: Znn                      ! Nuclear charge (> 0)

            ! INTERMEDIATE VARIABLES
            INTEGER :: i,j,k,l
            REAL*8 :: tmp

            ! OUTPUT
            REAL*8, dimension(Kf,Kf), intent(out) :: Vn     ! Nucleus-electron potential matrix

            Vn(:,:) = 0.0D0

            DO i = 1,Kf
                DO j = 1,Kf
                    DO k = 1,c
                        DO l = 1,c
                            tmp = basis_D(i,k) * basis_D(j,l)
                            tmp = tmp * nuclear_coeff(  basis_L(i,1),&      ! lx for basis function i
                                                        basis_L(i,2),&      ! ly for basis function i
                                                        basis_L(i,3),&      ! lz for basis function i
                                                        basis_L(j,1),&      ! lx for basis function j
                                                        basis_L(j,2),&      ! ly for basis function j
                                                        basis_L(j,3),&      ! lz for basis function j
                                                        basis_A(i,k),&      ! Exponential coefficient for basis function i, contraction k
                                                        basis_A(j,l),&      ! Exponential coefficient for basis function j, contraction l
                                                        basis_R(i,:),&      ! Center of basis function i
                                                        basis_R(j,:),&      ! Center of basis function j
                                                        Rnn,Znn)            ! Nuclear position and nuclear charge

                            Vn(i,j) = Vn(i,j) + tmp
                        END DO ! l
                    END DO ! k
                END DO ! j
            END DO ! i

        END SUBROUTINE V_nuclear


END MODULE NUCLEAR
