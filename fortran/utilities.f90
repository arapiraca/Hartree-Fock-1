SUBROUTINE gaussian_product(aa,bb,Ra,Rb,pp,Rp,cp)
    IMPLICIT NONE

    ! INPUT
    REAL*8, intent(in) :: aa, bb ! Gaussian exponential coefficients
    REAL*8, dimension(3), intent(in) :: Ra, Rb ! Gaussian centers

    ! INTERMEDIATE VARIABLE
    REAL*8, dimension(3) :: Rab ! Differente between Gaussian centers

    ! OUTPUT
    REAL*8, intent(out) :: pp ! Gaussian product exponential coefficient
    REAL*8, intent(out) :: cp ! Gaussian product coefficient
    REAL*8, dimension(3), intent(out) :: Rp ! Gaussian product center

    ! Compute Gaussian product exponential coefficient
    pp = aa + bb

    ! Compute difference between Gaussian centers
    Rab = Ra - Rb

    ! Compute Gaussian product coefficient
    cp = DOT_PRODUCT(Rab,Rab)
    cp =  - aa * bb / pp * cp
    cp = EXP(cp)

    ! Compute Gaussian product center
    Rp = (aa * Ra + bb * Rb) / pp

END SUBROUTINE gaussian_product











FUNCTION norm(ax,ay,az,aa) result(N)
    IMPLICIT NONE

    USE CONSTANTS

    ! INPUT
    INTEGER, intent(in) :: ax, ay, az ! Cartesian Gaussian angular momenta projections
    REAL*8, intent(in) :: aa ! Gaussian exponential coefficient

    ! OUTPUT
    REAL*8 :: N ! Normalization factor

    N = (2 * aa / PI)**(3. / 4.) * (4. * aa)**((ax + ay + ax) / 2.)
    N = N / SQRT(factorial2(2 * ax - 1) * factorial2(2 * ay - 1) * factorial2(2 * ax - 1))

END FUNCTION norm
