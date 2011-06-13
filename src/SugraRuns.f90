Module SugraRuns

! load modules
 Use Control
 Use LoopCouplings
 Use LoopMasses
 Use LoopFunctions
 Use Mathematics, Only: Li2, odeint, odeintB
 Use Model_Data, Only: MnuR
 Use RGEs
 Use StandardModel
! load modules

! global variables
Real(dp), save :: n5plets
Integer, save :: n10plets, YukScen
Real(dp), Save :: Lambda, MlambdaS, F_GMSB
! string scenarios
Integer, save :: num_t
Integer, save :: nH1_ai(36), nH2_ai(36), nE_ai(36,3), nL_ai(36,3)          &
     &   , nD_ai(36,3), nU_ai(36,3), nQ_ai(36,3), mH1_ai(36), mH2_ai(36)   &
     &   , mE_ai(36,3), mL_ai(36,3), mD_ai(36,3), mU_ai(36,3)              &
     &   , mQ_ai(36,3), mtH1_ai(36), mtH2_ai(36), mtE_ai(36,3)             &
     &   , mtL_ai(36,3), mtD_ai(36,3), mtU_ai(36,3), mtQ_ai(36,3)          &
     &   , n_ai(3,17), pLE(36,3,3), pEH1(36,3), pLH1(36,3), pQD(36,3,3)    &
     &   , pDH1(36,3), pQH1(36,3), pQU(36,3,3), pUH2(36,3), pQH2(36,3)     &
     &   , mG(36,3), pGE(36,3,3), pGL(36,3,3), pGD(36,3,3), pGU(36,3,3)    &
     &   , pGQ(36,3,3), pGH1(36,3), pGH2(36,3)
Real(dp), Save :: C_a(3), C_ai(3,20),  SumC_O1(3)
Real(dp), save :: m32, g_s, k_s, k_sb, k_ss, ThetaA(36)                     &
     &   , cosT, sumC1(3), sumC2(3), LnReDedekind(36), ReT(36)        &
     &   , oosqrt_k_ss, sinT, g_s2, delta_GS, sinT2, cosT2
Complex(dp), save :: phase_s, t(36), phase_t(36), G2t(36),ReG2ThetaT(36)
Real(dp), save :: mGUT_save, sinW2_DR_mZ      &
    & , mf_l_DR_SM(3), mf_d_DR_SM(3), mf_u_DR_SM(3)
Real(dp) :: m_32, M0_amsb
Complex(dp), save :: Yl_mZ(3,3), Yu_mZ(3,3), Yd_mZ(3,3)
! flag to decide if nu-Yukawas are given from outside or not
Logical, Save :: Fixed_Nu_Yukawas = .False., Ynu_eq_Yu = .False.
Logical, Save :: Off_GMSB=.False.
! check if in the super CKM basis are given
Logical, Save :: l_Au=.False., l_Ad=.False., l_Al=.False., l_MD = .False. &
    & , l_MQ = .False., l_MU = .False., l_ME = .False. , l_ML = .False. 
! global variables

! private variables
Integer, Private, save :: YukawaScheme=1
Logical, Private, save :: CheckSugraDetails(10) = .False. &
                & , SugraErrors(10) = .False.        &
                & , StrictUnification = .False.      &
                & , UseFixedScale = .False.          &
                & , UseFixedGUTScale = .False.
Real(dp), Private, Save :: GUT_scale
Character(len=15), Private, save :: HighScaleModel
! private variables

Contains


 Subroutine BoundaryEW(i_run, vevSM, mC, U, V, mN, N, mS02, RS0, mP02, RP0    &
    & , mSpm, mSpm2, RSpm, mDsquark, mDsquark2, RDsquark, mUsquark, mUsquark2 &
    & , RUsquark, mSlepton, mSlepton2, RSlepton, mSneutrino2 , RSneutrino     &
    & , uU_L, uU_R, uD_L, uD_R, uL_L, uL_R, mGlu, phase_glu, mZ2_run, mW2_run &
    & , delta0, g1, kont)
 !-----------------------------------------------------------------------
 ! Calculates gauge and yukawa couplings at m_Z in the DRbar scheme
 ! written by Werner Porod
 ! 15.11.01: - dummy version to get consistent program structure
 ! 16.11.01: - implementing gauge couplings
 !             please note that the call to PiZZ1 has to be changed for
 !             complex neutral scalar
 !           - implementing first steps for Yukawa couplings including
 !             an iterative process due to bottom Yukawa at large tan(beta)
 ! 25.12.01: - adding Sigma_Fermion
 ! 10.03.03: - adding call to Sigma_Fermion3
 !           - adding new routine Yukawas
 ! 26.03.04: - changing resummation in case of generation mixing
 !-----------------------------------------------------------------------
 Implicit None
  Integer, Intent(in) :: i_run
  Real(dp), Intent(inout) :: mSpm2(:)
  Real(dp), Intent(in) :: mC(:), mN(:), mSpm(:), mUsquark(:), mDsquark(:)     &
    & , mSlepton(:), mUsquark2(:), mDsquark2(:), mSlepton2(:), mSneutrino2(:) &
    & , mS02(:), mP02(:), RP0(:,:), mglu, RS0(:,:), vevSM(2), delta0
  Complex(dp), Intent(in) :: U(:,:), V(:,:), N(:,:), RSpm(:,:)           &
    & , RDsquark(:,:), RUsquark(:,:), RSlepton(:,:), RSneutrino(:,:)     &
    & , phase_glu
  Complex(dp), Intent(inout) :: uU_L(3,3), uU_R(3,3), uD_L(3,3), uD_R(3,3) &
    & , uL_L(3,3), uL_R(3,3)
  Real(dp), Intent(out) :: g1(57), mW2_run, mZ2_run
  Integer, Intent(inout) :: kont

  Integer :: n_S0, i1, i_loop, i_loop_max, i2
  Real(dp) :: mC2( Size(mC) ), mN2(Size(mN) ), D_mat(3,3)
  Real(dp) :: test, alphaMZ, alpha3, gSU2, rho, delta_rho, sinW2_DR, vev2    &
    & , vevs_DR(2), mZ2_mZ, CosW2SinW2, gauge(3), delta, sinW2_old, delta_r  &
    & , p2, gSU3, tanb, xt2, fac(2), SigQCD, delta_rw, sinW2, cosW2, cosW
  Real(dp), Dimension(3) :: mf_d_DR, mf_l_DR, mf_u_DR
  Complex(dp) :: dmZ2, dmW2, dmW2_0, yuk_tau, yuk_t, yuk_b, SigLep, Sigdown  &
    & , SigUp
  Complex(dp), Dimension(3,3) :: SigS_u, sigR_u, SigL_u, SigS_d, SigR_d    &
    & , SigL_d, SigS_l, sigR_l, SigL_l, Y_u, Y_d, Y_l, adCKM, uU_L_T, uU_R_T &
    & , uD_L_T, uD_R_T, uL_L_T, uL_R_T, Y_l_old, Y_d_old, Y_u_old
  Logical :: converge
  Real(dp), Parameter :: e_d=-1._dp/3._dp, e_u=2._dp/3._dp, e_e=-1._dp &
    & , T3_d=-0.5_dp, T3_u=0.5_dp, mf_nu(3) = (/0._dp, 0._dp, 0._dp /)
  Complex(dp), Parameter :: Y_nu(3,3) = ZeroC
  Complex(dp), Dimension(6,6) :: rot, RUsq_ckm, RDsq_ckm, RUsq_in, RDsq_in

  Iname = Iname + 1
  nameOfUnit(Iname) = "BoundaryEW"
  !----------------------------------------
  ! checking if masses squared are positiv
  !----------------------------------------
  If (Min(Minval(mUsquark2), Minval(mDSquark2), Minval(mSlepton2)           &
     &    ,Minval(mSneutrino2), Minval(mS02), Minval(mP02), Minval(mSpm2))  &
     & .Lt. 0._dp ) Then
   kont = -401
   Call AddError(401)
   Iname = Iname - 1
   Return
  End If

  sinW2 = 1._dp - mW2/mZ2
  mC2 = mC**2
  mN2 = mN**2
  n_s0 = Size(mS02)
  !-------------------------------------------------------------------
  ! setting renormalisation scale to m_Z, because the RGEs start there
  !-------------------------------------------------------------------
  test = SetRenormalizationScale(mZ2)
  tanb = vevSM(2) / vevSM(1)
  !-------------------------------------------------------------------
  ! initialization of LoopMasses
  !-------------------------------------------------------------------
  Call  SetLoopMassModel(Size(mC), Size(mN), n_s0, n_s0, Size(mSpm) &
                       & , Size(mSlepton), Size(msneutrino2))
  !-----------
  ! alpha(mZ)
  !-----------
  alphaMZ = AlphaEwDR(mZ, mSpm, mUsquark, mDSquark, mSlepton, mC)
  !-----------
  ! alpha_s(mZ)
  !-----------
  alpha3 = AlphaSDR(mZ, mglu, mUSquark, mDSquark)
  gSU3 = Sqrt( 4._dp*pi*alpha3)
  !-----------------
  ! sin(theta_W)^2
  !-----------------
  If (i_run.Eq.1) Then
   sinW2_DR = sinW2
   sinW2_old = sinW2_DR
   Y_l = 0._dp
   Do i1=1,3
    y_l(i1,i1) = sqrt2 * mf_l_mZ(i1) / vevSM(1)
   End Do
  Else
   sinW2_DR = sinW2_DR_mZ
   sinW2_old = sinW2_DR
   Y_l = Yl_mZ
  End If
  !--------------------
  ! for 2-loop parts
  !--------------------
   xt2 = 3._dp * (G_F * mf_u2(3) * oo8pi2 * oosqrt2)**2        &
      & * Abs(RS0(1,2))**2 * rho_2(Sqrt(mS02(1))/mf_U(3))     &
      & * ((1._dp+tanb**2)/tanb**2) 
   fac(1) = alphaMZ * alphaS_mZ * oo4pi                                    &
        & * (2.145_dp * mf_u2(3)/mZ2 + 0.575 * Log(mf_u(3)/mZ) - 0.224_dp  &
        &   - 0.144_dp * mZ2 / mf_u2(3)) / Pi
   fac(2) = alphamZ * alphaS_mZ * oo4pi                                    &
       & * (-2.145_dp * mf_u2(3)/mW2 + 1.262 * Log(mf_u(3)/mZ) - 2.24_dp  &
       &   - 0.85_dp * mZ2 / mf_u2(3)) / Pi 

  Do i1=1,100
   gSU2 = Sqrt( 4._dp*pi*alphamZ/sinW2_DR)
   Call PiZZT1(mZ2, gSU2, sinW2_DR, vevSM, mZ2, mW2, mS02, RS0, mP02, RP0   &
   & , mSpm2, RSpm, mSneutrino2, RSneutrino, mSlepton2, RSlepton, mUsquark2 &
   & , RUsquark, mDSquark2, RDSquark, mf_l2, mf_u2, mf_d2, mC, mC2, U, V    &
   & , mN, mN2, N, dmZ2)
   mZ2_mZ = Real(dmZ2+mZ2,dp)
   If (mZ2_mZ.Lt.0._dp) Then
    Iname = Iname - 1
    kont = -407 
    Return
   End If
   mZ2_run = mZ2_mZ
   mW2_run = mZ2_mZ * (1._dp - sinW2_DR)
   !---------------------------------------
   ! recalculation, using running masses
   !---------------------------------------
   Call PiZZT1(mZ2, gSU2, sinW2_DR, vevSM, mZ2_mZ, mW2_run, mS02, RS0         &
   & , mP02, RP0, mSpm2, RSpm, mSneutrino2, RSneutrino, mSlepton2, RSlepton   &
   & , mUsquark2, RUsquark, mDSquark2, RDSquark, mf_l2, mf_u2, mf_d2, mC, mC2 &
   & , U, V, mN, mN2, N  &
   & , dmZ2)
   mZ2_mZ = Real(dmZ2+mZ2,dp)
   If (mZ2_mZ.Lt.0._dp) Then
    Iname = Iname - 1
    kont = -407 
    Return
   End If
   mZ2_run = mZ2_mZ
   mW2_run = mZ2_mZ * (1._dp - sinW2_DR)

   Call PiWWT1(mW2, gSU2, sinW2_DR, mS02, RS0, mSpm2, RSpm, vevSM          &
         & , mP02, RP0, mSneutrino2, RSneutrino, mSlepton2, RSlepton       &
         & , mUSquark2, RUSquark, mDSquark2, RDSquark, mf_l2, mf_u2, mf_d2 &
         & , CKM, mN, mN2, N, mC, mC2, U, V, mZ2_mZ, mW2_run, dmW2)

   Call PiWWT1(0._dp, gSU2, sinW2_DR, mS02, RS0, mSpm2, RSpm , vevSM       &
         & , mP02, RP0, mSneutrino2, RSneutrino, mSlepton2, RSlepton       &
         & , mUSquark2, RUSquark, mDSquark2, RDSquark, mf_l2, mf_u2, mf_d2 &
         & , CKM, mN, mN2, N, mC, mC2, U, V, mZ2_mZ, mW2_run, dmW2_0)

   rho = (1._dp + Real(dmZ2,dp)/mZ2) / (1._dp + Real(dmW2,dp) / mW2)
   delta_rho = 1._dp - 1._dp / rho 

   CosW2SinW2 = (1._dp - sinW2_DR) * sinW2_DR
   Call delta_VB(gSU2, sinW2, sinW2_DR, rho, mC, mC2, U, V, mN, mN2, N &
                &, Y_l, mSlepton2, Rslepton, mSneutrino2, RSneutrino, delta)
   delta_r = rho*Real(dmW2_0,dp)/mW2 - Real(dmZ2,dp) / mZ2 + delta
   rho = 1._dp /  (1._dp - delta_rho - fac(2) / sinW2_DR - xt2)
   delta_r = rho*Real(dmW2_0,dp)/mW2 - Real(dmZ2,dp) / mZ2 + delta   &
         & + fac(1) / CosW2SinW2 - xt2 * (1-delta_r) * rho
   CosW2SinW2 = pi * alphamZ / (sqrt2 * mZ2 * G_F * (1-delta_r) )
   sinW2_DR = 0.5_dp - Sqrt(0.25_dp - CosW2SinW2)
   If (sinW2_DR.Lt.0._dp) Then
    kont = -412
    Iname = Iname -1
    Return
   End If
   If (Abs(sinW2_DR-sinW2_old).Lt. 0.1_dp*delta0) Exit
   sinW2_old = sinW2_DR
   delta_rw = delta_rho*(1._dp-delta_r) + delta_r
   If ((0.25_dp-alphamz*pi/(sqrt2*G_F*mz2*rho*(1._dp-delta_rw))).Lt.0._dp) Then
    kont = -406
    If (Errorlevel.Ge.0) Then
     Write(Errcan,*) "Problem in subroutine "//NameofUnit(Iname)
     Write(Errcan,*) "In the calculation of mW", &
          & 0.25_dp-alphamz*pi/(sqrt2*G_F*mz2*rho*(1._dp-delta_rw))
     Write(errcan,*) "mf_l_mZ, vevSM"
     Write(errcan,*) mf_l_mZ,vevSM
     Write(errcan,*) "mZ2_mZ, dmW2, dmW2_0, rho, delta_rho, sinW2_DR"
     Write(errcan,*) mZ2_mZ, dmW2, dmW2_0, rho, delta_rho, sinW2_DR
     Write(ErrCan,*) "delta_r, cosW2SinW2, delta_rw"
     Write(ErrCan,*) delta_r, cosW2SinW2, delta_rw
    End If
    kont = -411
    Iname = Iname - 1
    Return
   End If
   mW2 = mZ2 * rho * ( 0.5_dp &
      &         +Sqrt(0.25_dp-alphamz*pi/(sqrt2*G_F*mz2*rho*(1._dp-delta_rw))))

   mSpm2(1) = mW2_run ! for this loop
   cosW2 = mW2 / mZ2
   cosW = Sqrt(cosW2)
   sinW2 = 1._dp - cosW2
  End Do
  mSpm2(1) = mW2
  !--------------------------------------------------------------------------
  ! recalcuating m_W and sin^2_W, the formula for m_W is base on Eq.25 of
  ! G.Degrassi et al., NPB351, 49 (1991)  
  !--------------------------------------------------------------------------
  delta_rw = delta_rho*(1._dp-delta_r) + delta_r
  mW2 = mZ2 * rho * ( 0.5_dp &
      &         +Sqrt(0.25_dp-alphamz*pi/(sqrt2*G_F*mz2*rho*(1._dp-delta_rw))))
  mW = Sqrt(mW2)
  cosW2 = mW2 / mZ2
  cosW = Sqrt(cosW2)
  sinW2 = 1._dp - cosW2
  !---------------------------
  ! gauge couplings and vevs
  !---------------------------
  gauge(1) = Sqrt( 4._dp*pi*alphamZ/(1._dp-sinW2_DR) )
  gauge(2) = Sqrt( 4._dp*pi*alphamZ/sinW2_DR)
  gauge(3) = Sqrt( 4._dp*pi*alpha3)
  vev2 =  mZ2_mZ * CosW2SinW2 / (pi * alphamZ)
  vevs_DR(1) = Sqrt(vev2 / (1._dp+tanb**2) )
  vevs_DR(2) = tanb * vevs_DR(1)


  !-------------------------------------
  ! Initialize fermion mixing matrices
  !-------------------------------------
  uU_L = id3C
  uU_R = id3C
  uD_L = id3C
  uD_R = id3C
  uL_L = id3C
  uL_R = id3C
  If (GenerationMixing) Then
   Call Adjungate(CKM, adCKM)
   If (YukawaScheme.Eq.1) Then
    uU_L = CKM
   Else
    uD_L = adCKM
   End If
  End If

  If (i_run.Eq.1) Then
   !--------------------------------------------------------------------------
   ! shifting light fermion masses to DR-scheme, only gluon and photon part
   ! except for m_t
   !--------------------------------------------------------------------------
   mf_l_DR_SM = &
    &     mf_l_mZ * (1._dp - oo8pi2 *3._dp *(gauge(1)**2-gauge(2)**2)/16._dp)
   mf_d_DR_SM = mf_d_mZ * (1._dp - alpha3 / (3._dp*pi)                  &
         &               - 23._dp * alpha3**2 / (72._dp * Pi2 )         &
         &               + oo8pi2 * 3._dp * gauge(2)**2 / 16._dp        &
         &               - oo8pi2 * 13._dp * gauge(1)**2 / 144._dp  )
   mf_u_DR_SM(1:2) = mf_u_mZ(1:2)  * (1._dp - alpha3 / (3._dp*pi)       &
         &               - 23._dp * alpha3**2 / (72._dp * Pi2 )         &
         &               + oo8pi2 * 3._dp * gauge(2)**2 / 16._dp        &
         &               - oo8pi2 * 7._dp * gauge(1)**2 / 144._dp  )
   mf_u_DR_SM(3) = mf_u(3) ! QCD + QED shift will be added later
   mf_l_DR = mf_l_DR_SM
   mf_d_DR = mf_d_DR_SM
   mf_u_DR = mf_u_DR_SM
   !---------------------------------------------------------------------
   ! Yukawa couplings
   !--------------------------------------------------------------------
   Y_d = 0._dp
   Y_u = 0._dp 
   Y_l = 0._dp
   Do i1=1,3
    Y_u(i1,i1) = sqrt2 * mf_u_DR_SM(i1) / vevs_DR(2)
    Y_l(i1,i1) = sqrt2 * mf_l_DR_SM(i1) / vevs_DR(1)
    Y_d(i1,i1) = sqrt2 * mf_d_DR_SM(i1) / vevs_DR(1)
   End Do
   If (GenerationMixing) Then
    If (YukawaScheme.Eq.1) Then
     Y_u = Matmul(Transpose(uU_L),Y_u) 
    Else
     Y_d = Matmul(Transpose(uD_L),Y_d) 
    End If
   End If
   !--------------------------------------------
   ! the starting point of the tree-level mixing
   !--------------------------------------------
   uU_L_T = uU_L
   uU_R_T = uU_R
   uD_L_T = uD_L
   uD_R_T = uD_R
   uL_L_T = uL_L
   uL_R_T = uL_R
  Else 
   !--------------------------------------------------------------------------
   ! take Yukawas from previous run
   !--------------------------------------------------------------------------
   Y_l = Yl_mZ
   Y_d = Yd_mZ
   Y_u = Yu_mZ
   Call FermionMass(Y_l,vevs_DR(1),mf_l_DR,uL_L_T,uL_R_T,kont)
   Call FermionMass(Y_d,vevs_DR(1),mf_d_DR,uD_L_T,uD_R_T,kont)
   Call FermionMass(Y_u,vevs_DR(2),mf_u_DR,uU_L_T,uU_R_T,kont)
  End If ! i_run.eq.1
   !---------------------------------------------
   ! shifting mixing matrices to superCKM basis 
   !---------------------------------------------
    rot = 0._dp
    rot(1:3,1:3) = Conjg(uU_L_T)
    rot(4:6,4:6) = uU_R_T
    RUsq_ckm = Matmul(RUSquark, Transpose(rot))

    rot = 0._dp
    rot(1:3,1:3) = Conjg(uD_L_T)
    rot(4:6,4:6) = uD_R_T
    RDsq_ckm = Matmul(RDSquark, Transpose(rot))

  converge = .False.

  Y_l_old = Y_l
  Y_d_old = Y_d
  Y_u_old = Y_u
  !------------------------------
  ! now the iteration
  !------------------------------
  if (FermionMassResummation) then
   i_loop_max = 100 ! this should be sufficient
  else
   i_loop_max = 1
  end if
  Do i_loop =1,i_loop_max
   yuk_b = Y_d(3,3)! for checking of convergence
   yuk_t = Y_u(3,3)
   yuk_tau = Y_l(3,3)

   If (GenerationMixing) Then
    !---------------------------------------------------------------
    ! rotate squarks from superCKM basis to new electroweak basis
    !---------------------------------------------------------------
    rot = 0._dp
    rot(1:3,1:3) = uU_L_T
    rot(4:6,4:6) = Conjg(uU_R_T)
    RUsq_in = Matmul(RUsq_ckm, rot)
    rot = 0._dp
    rot(1:3,1:3) = uD_L_T
    rot(4:6,4:6) = Conjg(uD_R_T)
    rot = 0._dp
    RDsq_in = Matmul(RDsq_ckm, rot)

    p2 = 0._dp ! for off-diagonal elements
    ! u-quarks
    Call Sigma_Fermion3(p2, mf_u_DR, Y_u, uU_L_T, uU_R_T, gSU2, gSU3, sinW2_DR &
        & , T3_u, e_u, mf_d_DR, Y_d, uD_L_T, uD_R_T, mUSquark2,RUsq_in         &
        & , mDSquark2, RDsq_in, mglu , phase_glu, mN, mN2, N, mC, mC2, U, V   &
        & , mS02, RS0, mP02, RP0, mSpm2 , RSpm, mZ2_run, mW2_run, .True.       &
        & , SigS_u, SigL_u, SigR_u, SigQCD)
    ! d-quarks
    Call Sigma_Fermion3(p2, mf_d_DR, Y_d, uD_L_T, uD_R_T, gSU2, gSU3, sinW2_DR &
        & , T3_d, e_d, mf_u_DR, Y_u, uU_L_T, uU_R_T, mDSquark2, RDsq_in        &
        & , mUSquark2, RUsq_in,  mglu , phase_glu, mN, mN2, N, mC, mC2, U, V   &
        & , mS02, RS0, mP02, RP0, mSpm2 , RSpm, mZ2_run, mW2_run , .True.      &
        & , SigS_d, SigL_d, SigR_d)
    ! leptons
    Call Sigma_Fermion3(p2, mf_l_DR, Y_l, uL_L, uL_R, gSU2, gSU3, sinW2_DR    &
        & , T3_d, e_e, mf_nu, Y_nu, id3C, id3C, mSlepton2, RSlepton           &
        & , mSneutrino2, RSneutrino, mglu , phase_glu, mN, mN2, N, mC, mC2, U &
        & , V, mS02, RS0, mP02, RP0, mSpm2 , RSpm, mZ2_run, mW2_run, .False.  &
        & , SigS_l, SigL_l, SigR_l)

    mf_u_DR_SM(3) = mf_u(3) + SigQCD
    Call Yukawas(mf_u_DR_SM, vevs_DR(2), uU_L, uU_R, SigS_u, SigL_u, SigR_u &
          & , Y_u, .False., kont)

    If (kont.Ne.0) Then
     Iname = Iname - 1
     Return
    End If
    Call Yukawas(mf_d_DR_SM, vevs_DR(1), uD_L, uD_R, SigS_d, SigL_d, SigR_d &
!          & , Y_d, .false., kont)
          & , Y_d, FermionMassResummation, kont)

    If (kont.Ne.0) Then
     Iname = Iname - 1
     Return
    End If
    Call Yukawas(mf_l_DR_SM, vevs_DR(1), id3C, id3C, SigS_l, SigL_l, SigR_l &
          & , Y_l, FermionMassResummation, kont)

    If (kont.Ne.0) Then
     Iname = Iname - 1
     Return
    End If

    !----------------------------------------------------------------
    ! I am only interested in the mixing matrices and, thus, it does
    ! not matter which vev I am using
    !----------------------------------------------------------------
    Call FermionMass(Y_l,vevs_DR(1),mf_l_DR,uL_L_T,uL_R_T,kont)
    Call FermionMass(Y_d,vevs_DR(1),mf_d_DR,uD_L_T,uD_R_T,kont)
    Call FermionMass(Y_u,vevs_DR(2),mf_u_DR,uU_L_T,uU_R_T,kont)

    converge = .True.
    D_mat = Abs(Abs(Y_l) - Abs(Y_l_old))
    Where (Abs(Y_l).Ne.0._dp) D_mat = D_mat / Abs(Y_l)
    Do i1=1,3
     If (D_mat(i1,i1).Gt.0.1_dp*delta0) converge = .False.
     Do i2=i1+1,3
      If (D_mat(i1,i2).Gt.delta0) converge = .False.
      If (D_mat(i2,i1).Gt.delta0) converge = .False.
     End Do
    End Do
    D_mat = Abs(Abs(Y_d) - Abs(Y_d_old))
    Where (Abs(Y_d).Ne.0._dp) D_mat = D_mat / Abs(Y_d)
    Do i1=1,3
     If (D_mat(i1,i1).Gt.0.1_dp*delta0) converge = .False.
     Do i2=i1+1,3
      If (D_mat(i1,i2).Gt.10._dp*delta0) converge = .False.
      If (D_mat(i2,i1).Gt.10._dp*delta0) converge = .False.
     End Do
    End Do
    D_mat = Abs(Abs(Y_u) - Abs(Y_u_old))
    Where (Abs(Y_u).Ne.0._dp) D_mat = D_mat / Abs(Y_u)
    Do i1=1,3
     If (D_mat(i1,i1).Gt.0.1_dp*delta0) converge = .False.
     Do i2=i1+1,3
      If (D_mat(i1,i2).Gt.10._dp*delta0) converge = .False.
      If (D_mat(i2,i1).Gt.10._dp*delta0) converge = .False.
     End Do
    End Do

    If (converge) Exit

    Y_l_old = Y_l
    Y_u_old = Y_u
    Y_d_old = Y_d

  Else ! .not.GenerationMixing
   Do i1=1,3

     p2 = mf_d_DR(i1)**2
     Call Sigma_Fermion(p2, i1, mf_d_DR, Y_d, id3C, id3C,gSU2,gSU3,sinW2_DR   &
      & ,T3_d, e_d, mf_u_DR, Y_u, id3C, id3C, mDSquark2, RDSquark, mUSquark2  &
      & ,RUSquark, mglu, phase_glu, mN, mN2, N, mC, mC2, U, V, mS02, RS0      &
      & ,mP02, RP0, mSpm2, RSpm, mZ2_run, mW2_run, .True., .True., SigDown)
     If (FermionMassResummation) Then
      mf_d_DR(i1) = mf_d_DR_SM(i1) / (1- Real(SigDown,dp) / mf_d_DR(i1) )
     Else
      mf_d_DR(i1) = mf_d_DR_SM(i1) + Real(SigDown,dp)
     End If
     Y_d(i1,i1) = sqrt2 * mf_d_DR(i1) / vevs_DR(1)

     p2 = mf_u_DR(i1)**2
     If (i1.Lt.3) Then
      Call Sigma_Fermion(p2, i1, mf_u_dR, Y_u, id3C, id3C, gSU2, gSU3,sinW2_DR&
        & ,T3_u, e_u, mf_d_DR, Y_d, id3C, id3C,mUSquark2,RUSquark,mDSquark2   &
        & ,RDSquark, mglu, phase_glu, mN, mN2, N, mC, mC2, U, V, mS02, RS0    &
        & ,mP02, RP0, mSpm2, RSpm, mZ2_run, mW2_run, .True., .True., SigUp)
     Else
      Call Sigma_Fermion(p2, i1, mf_u_DR, Y_u, id3C, id3C, gSU2, gSU3,sinW2_DR&
        & ,T3_u, e_u, mf_d_DR, Y_d, id3C, id3C,mUSquark2,RUSquark,mDSquark2   &
        & ,RDSquark, mglu, phase_glu, mN, mN2, N, mC, mC2, U, V, mS02, RS0    &
        & ,mP02, RP0, mSpm2, RSpm, mZ2_run, mW2_run, .True., .False., SigUp)
     End If
     mf_u_DR(i1) = mf_u_DR_SM(i1) + Real(SigUp,dp)
     Y_u(i1,i1) = sqrt2 * mf_u_DR(i1) / vevs_DR(2)

     p2 = mf_l_DR(i1)**2
     Call Sigma_Fermion(p2, i1, mf_l, Y_l, id3C, id3C, gSU2, gSU3, sinW2_DR  &
        & , T3_d, e_e, mf_nu, Y_nu, id3C, id3C, mSlepton2, RSlepton          &
        & , mSneutrino2, RSneutrino, mglu, phase_glu, mN, mN2, N, mC, mC2, U &
        & , V, mS02, RS0, mP02, RP0, mSpm2, RSpm, mZ2_run, mW2_run           &
        & , .False., .True., SigLep)
     If (FermionMassResummation) Then
      mf_l_DR(i1) = mf_l_DR_SM(i1) / (1- Real(SigLep,dp) / mf_l_DR(i1) )
     Else
      mf_l_DR(i1) = mf_l_DR_SM(i1) + Real(SigLep,dp)
     End If
     Y_l(i1,i1)  = sqrt2 * mf_l_DR(i1) / vevs_DR(1)
    
    End Do

    If (    (      Abs((yuk_tau-y_l(3,3))/y_l(3,3)).Lt. 0.1_dp*delta0) &
        &    .And.(Abs((yuk_t-y_u(3,3))  /y_u(3,3)).Lt. 0.1_dp*delta0) &
        &    .And.(Abs((yuk_b-y_d(3,3))  /y_d(3,3)).Lt. 0.1_dp*delta0) ) Then
     converge = .True.
     Exit
    End If
   End If  ! GenerationMixing

   !--------------------------------------------------
   ! Either we have run into a numerical problem or
   ! perturbation theory breaks down
   !--------------------------------------------------

   If (    (Minval(Abs(mf_l_DR/mf_l)).Lt.0.1_dp)  &
     & .Or.(Maxval(Abs(mf_l_DR/mf_l)).Gt.10._dp) ) Then
    Iname = Iname - 1
    kont = -408
    Return
   Else If (    (Minval(Abs(mf_d_DR/mf_d)).Lt.0.1_dp)  &
          & .Or.(Minval(Abs(mf_d_DR/mf_d)).Gt.10._dp) ) Then
    Iname = Iname - 1
    kont = -409
    Return
   Else If (    (Minval(Abs(mf_u_DR/mf_u)).Lt.0.1_dp)  &
          & .Or.(Minval(Abs(mf_u_DR/mf_u)).Gt.10._dp) ) Then
    Iname = Iname - 1
    kont = -410
    Return
   End If

  End Do ! i_loop
!Write(*,*) "i_loop",i_loop

  If ((.Not.converge).and.FermionMassResummation) Then
   Write (ErrCan,*) 'Problem in subroutine BoundaryEW!!'
   Write (ErrCan,*) "After",i_loop-1,"iterations no convergence of Yukawas"
   Write (ErrCan,*) 'yuk_tau,yuk_l(3,3)',yuk_tau,y_l(3,3)
   Write (ErrCan,*) 'yuk_b,yuk_d(3,3)',yuk_b,y_d(3,3)
   Write (ErrCan,*) 'yuk_t,yuk_u(3,3)',yuk_t,y_u(3,3)
  End If
!Write(41,*) "h",mp02(2)+mp02(1),ms02(2)+ms02(1),mp02(1)-mz2
!Write(41,*) sqrt(mp02(1)),sqrt(mz2)
  !----------------------------------------------------------------
  ! the RGE paper defines the Yukawas transposed to my conventions
  !----------------------------------------------------------------
  Yl_mZ = Y_l
  Yd_mZ = Y_d
  Yu_mZ = Y_u
  Y_u = Transpose(Y_u)
  Y_d = Transpose(Y_d)
  Y_l = Transpose(Y_l)
  sinW2_DR_mZ = sinW2_DR
  gauge(1) = Sqrt( 5._dp/3._dp) * gauge(1)
  gauge_mZ = gauge

  Call  CouplingsToG(gauge, y_l, y_d, y_u, g1)

  !----------------------------------------------
  ! resetting scale
  !----------------------------------------------
  test = SetRenormalizationScale(test)

  Iname = Iname - 1

 Contains

  Real(dp) Function rho_2(r)
  Implicit None
   Real(dp), Intent(in) :: r
   Real(dp) :: r2, r3
   r2 = r*r
   r3 = r2*r
   rho_2 = 19._dp - 16.5_dp * r + 43._dp * r2 / 12._dp             &
       & + 7._dp * r3 / 120._dp                                    &
       & - Pi * Sqrt(r) * (4._dp - 1.5_dp * r + 3._dp * r2/32._dp  &
       &                  + r3/256._dp)                             &
       & - Pi2 * (2._dp - 2._dp * r + 0.5_dp * r2)                 &
       & - Log(r) * (3._dp * r - 0.5_dp * r2) 
  End  Function rho_2

  Subroutine Yukawas(mf, vev, uL, uR, SigS, SigL, SigR, Y, ReSum, kont)
  !--------------------------------------------------------
  ! solves the matrix equation for Y by a transformation to
  ! a linear system of 9 equations in 9 unknowns
  ! written by Werner Porod, 19.03.03
  !--------------------------------------------------------
  Implicit None
   Integer, Intent(inout) :: kont
   Real(dp), Intent(in) :: mf(3), vev
   Complex(dp), Dimension(3,3), Intent(in) :: uL, uR, SigS, SigL, SigR
   Logical, Intent(in) :: ReSum
   Complex(dp), Intent(inout) :: Y(3,3)

   Integer :: i1
   Complex(dp), Dimension(3,3) :: mass, uLa, uRa, f, invf, invY

   !-------------------------------------
   ! first the mass matrix in DR scheme
   !-------------------------------------
   Call Adjungate(uL, uLa)
   Call Adjungate(uR, uRa)
   mass = ZeroC
   Do i1=1,3
    mass(i1,i1) = mf(i1)
   End Do
   mass = Matmul( Transpose(uL), Matmul(mass, uR) )
   !----------------------------------------
   ! setting up the equations
   !----------------------------------------
   Y = Y * vev * oosqrt2
   If (ReSum) Then
    kont = 0
    Call chop(Y)
    invY = Y
    Call gaussj(kont,invY,3,3)
    If (kont.Ne.0) Return

    f = id3C - Matmul(SigS,invY) - Transpose(SigL) - Matmul(Y,Matmul(SigR,invY))
    invf = f
    Call gaussj(kont,invf,3,3)
    If (kont.Ne.0) Return

    Y = Matmul(invf,mass)

   Else

    Y = mass + SigS + Matmul(Transpose(SigL),Y) + Matmul(Y,SigR)

   End If

   Y = sqrt2 * Y / vev

   Call chop(y)

  End Subroutine Yukawas

 End Subroutine BoundaryEW
 
 Subroutine BoundaryEW_2(i_run, Q_EWSB, vevSM, mC, U, V, mN, N, mS02, RS0, mP02, RP0  &
    & , mSpm, mSpm2, RSpm, mDsquark, mDsquark2, RDsquark, mUsquark, mUsquark2 &
    & , RUsquark, mSlepton, mSlepton2, RSlepton, mSneutrino2 , RSneutrino     &
    & , uU_L, uU_R, uD_L, uD_R, uL_L, uL_R, mGlu, phase_glu, mZ2_run, mW2_run &
    & , delta0, g1, kont)
 !-----------------------------------------------------------------------
 ! Calculates the SM gauge and yukawa couplings at m_Z, which are evolved
 ! to Q_EWSB where the SUSY corrections are included.
 ! written by Werner Porod
 ! 07.01.09:taking  BoundaryEW as a start
 !-----------------------------------------------------------------------
 Implicit None
  Integer, Intent(in) :: i_run
  Real(dp), Intent(inout) :: mSpm2(:)
  Real(dp), Intent(in) :: mC(:), mN(:), mSpm(:), mUsquark(:), mDsquark(:)     &
    & , mSlepton(:), mUsquark2(:), mDsquark2(:), mSlepton2(:), mSneutrino2(:) &
    & , mS02(:), mP02(:), RP0(:,:), mglu, RS0(:,:), vevSM(2), delta0, Q_EWSB
  Complex(dp), Intent(in) :: U(:,:), V(:,:), N(:,:), RSpm(:,:)           &
    & , RDsquark(:,:), RUsquark(:,:), RSlepton(:,:), RSneutrino(:,:)     &
    & , phase_glu
  Complex(dp), Intent(inout) :: uU_L(3,3), uU_R(3,3), uD_L(3,3), uD_R(3,3) &
    & , uL_L(3,3), uL_R(3,3)
  Real(dp), Intent(out) :: g1(57), mW2_run, mZ2_run
  Integer, Intent(inout) :: kont

  Integer :: n_S0, i1, i_loop, i2
  Real(dp) :: mC2( Size(mC) ), mN2(Size(mN) ), D_mat(3,3), mH2, vev, logQ
  Real(dp) :: test, alphaMZ, alpha3, gSU2, rho, delta_rho, sinW2_DR, vev2    &
    & , vevs_DR(2), mZ2_mZ, CosW2SinW2, gauge(3), delta, sinW2_old, delta_r  &
    & , p2, gSU3, tanb, xt2, fac(2), SigQCD, delta_rw, sinW2, cosW2, cosW
  Real(dp), Dimension(3) :: mf_d_DR, mf_l_DR, mf_u_DR
  Complex(dp) :: dmZ2, dmW2, dmW2_0, yuk_tau, yuk_t, yuk_b, SigLep, Sigdown  &
    & , SigUp
  Complex(dp), Dimension(3,3) :: SigS_u, sigR_u, SigL_u, SigS_d, SigR_d    &
    & , SigL_d, SigS_l, sigR_l, SigL_l, Y_u, Y_d, Y_l, adCKM, uU_L_T, uU_R_T &
    & , uD_L_T, uD_R_T, uL_L_T, uL_R_T, Y_l_old, Y_d_old, Y_u_old
  Logical :: converge
  Real(dp), Parameter :: e_d=-1._dp/3._dp, e_u=2._dp/3._dp, e_e=-1._dp &
    & , T3_d=-0.5_dp, T3_u=0.5_dp, mf_nu(3) = (/0._dp, 0._dp, 0._dp /)
  Complex(dp), Parameter :: Y_nu(3,3) = ZeroC
  Complex(dp), Dimension(6,6) :: rot, RUsq_ckm, RDsq_ckm, RUsq_in, RDsq_in

  Real(dp), Parameter :: &
    & as2loop = 1._dp / 24._dp + 2011._dp * oo32Pi2 / 12._dp           &
    &         + Log2 / 12._dp - oo8Pi2 * Zeta3                        &
    & , log2loop_a = 123._dp * oo32Pi2, log2loop_b = 33._dp * oo32Pi2

  Iname = Iname + 1
  nameOfUnit(Iname) = "BoundaryEW_2"
  !----------------------------------------
  ! checking if masses squared are positiv
  !----------------------------------------
  If (Min(Minval(mUsquark2), Minval(mDSquark2), Minval(mSlepton2)           &
     &    ,Minval(mSneutrino2), Minval(mS02), Minval(mP02), Minval(mSpm2))  &
     & .Lt. 0._dp ) Then
   kont = -401
   Call AddError(401)
   Iname = Iname - 1
   Return
  End If

  sinW2 = 1._dp - mW2/mZ2
  mC2 = mC**2
  mN2 = mN**2
  n_s0 = Size(mS02)
  !-------------------------------------------------------------------
  ! setting renormalisation scale to m_Z, because the RGEs start there
  !-------------------------------------------------------------------
  test = SetRenormalizationScale(mZ2)
  tanb = vevSM(2) / vevSM(1)
  !-------------------------------------------------------------------
  ! initialization of LoopMasses
  !-------------------------------------------------------------------
  Call  SetLoopMassModel(Size(mC), Size(mN), n_s0, n_s0, Size(mSpm) &
                       & , Size(mSlepton), Size(msneutrino2))
  !-------------------------------------------------------------------
  ! alpha(mZ), include also m_t part, to get a SU(2) invariant model
  !-------------------------------------------------------------------
  alphaMZ = Alpha_MSbar(mZ, mW, mf_u(3))
  
  !-----------
  ! alpha_s(mZ)
  !-----------
  alpha3 = AlphaS_mZ / ( 1._dp - AlphaS_mZ * oo4pi &
         &                       * (1._dp - 4._dp * Log(mf_u(3)/mZ) / 3._dp ) )
  gSU3 = Sqrt( 4._dp*pi*alpha3)
  !-----------------
  ! sin(theta_W)^2
  !-----------------
  If (i_run.Eq.1) Then
   sinW2_DR = sinW2
   sinW2_old = sinW2_DR
   Y_l = 0._dp
   Do i1=1,3
    y_l(i1,i1) = sqrt2 * mf_l_mZ(i1) / vevSM(1)
   End Do
  Else
   sinW2_DR = sinW2_DR_mZ
   sinW2_old = sinW2_DR
   Y_l = Yl_mZ
  End If
  !--------------------
  ! for 2-loop parts
  !--------------------
   xt2 = 3._dp * (G_F * mf_u2(3) * oo8pi2 * oosqrt2)**2        &
      & * rho_2(Sqrt(mS02(1))/mf_U(3))     &
      & * ((1._dp+tanb**2)/tanb**2) 
   fac(1) = alphaMZ * alphaS_mZ * oo4pi                                    &
        & * (2.145_dp * mf_u2(3)/mZ2 + 0.575 * Log(mf_u(3)/mZ) - 0.224_dp  &
        &   - 0.144_dp * mZ2 / mf_u2(3)) / Pi
   fac(2) = alphamZ * alphaS_mZ * oo4pi                                    &
       & * (-2.145_dp * mf_u2(3)/mW2 + 1.262 * Log(mf_u(3)/mZ) - 2.24_dp  &
       &   - 0.85_dp * mZ2 / mf_u2(3)) / Pi 

  mH2 = 100._dp**2  ! needs to be changed
  vev = Sqrt(vevSM(1)**2 + vevSM(2)**2)
  Do i1=1,100
   gSU2 = Sqrt( 4._dp*pi*alphamZ/sinW2_DR)
   Call PiZZT1_SM(mZ2, gSU2, sinW2_DR, vev, mZ2, mW2, mH2, mf_l2, mf_u2, mf_d2 &
                 & , dmZ2)
   mZ2_mZ = Real(dmZ2+mZ2,dp)
   If (mZ2_mZ.Lt.0._dp) Then
    Iname = Iname - 1
    kont = -407 
    Return
   End If
   mZ2_run = mZ2_mZ
   mW2_run = mZ2_mZ * (1._dp - sinW2_DR)
   vev = 2._dp * mW2_run / gSU2
   !---------------------------------------
   ! recalculation, using running masses
   !---------------------------------------
   Call PiZZT1_SM(mZ2, gSU2, sinW2_DR, vev, mZ2_mZ, mW2_run, mH2, mf_l2 &
                 & , mf_u2, mf_d2, dmZ2)
   mZ2_mZ = Real(dmZ2+mZ2,dp)
   If (mZ2_mZ.Lt.0._dp) Then
    Iname = Iname - 1
    kont = -407 
    Return
   End If
   mZ2_run = mZ2_mZ
   mW2_run = mZ2_mZ * (1._dp - sinW2_DR)

   Call PiWWT1_SM(mW2, gSU2, sinW2_DR, mH2, vev, mf_l2, mf_u2, mf_d2 &
         & , CKM, mZ2_mZ, mW2_run, dmW2)

   Call PiWWT1_SM(0._dp, gSU2, sinW2_DR, mH2, vev, mf_l2, mf_u2, mf_d2 &
         & , CKM, mZ2_mZ, mW2_run, dmW2)

   rho = (1._dp + Real(dmZ2,dp)/mZ2) / (1._dp + Real(dmW2,dp) / mW2)
   delta_rho = 1._dp - 1._dp / rho 

   CosW2SinW2 = (1._dp - sinW2_DR) * sinW2_DR
   Call delta_VB_SM(gSU2, sinW2, sinW2_DR, rho, delta)
   delta_r = rho*Real(dmW2_0,dp)/mW2 - Real(dmZ2,dp) / mZ2 + delta
   rho = 1._dp /  (1._dp - delta_rho - fac(2) / sinW2_DR - xt2)
   delta_r = rho*Real(dmW2_0,dp)/mW2 - Real(dmZ2,dp) / mZ2 + delta   &
         & + fac(1) / CosW2SinW2 - xt2 * (1-delta_r) * rho
   CosW2SinW2 = pi * alphamZ / (sqrt2 * mZ2 * G_F * (1-delta_r) )
   sinW2_DR = 0.5_dp - Sqrt(0.25_dp - CosW2SinW2)
   If (sinW2_DR.Lt.0._dp) Then
    kont = -412
    Iname = Iname -1
    Return
   End If
   If (Abs(sinW2_DR-sinW2_old).Lt. 0.1_dp*delta0) Exit
   sinW2_old = sinW2_DR
   delta_rw = delta_rho*(1._dp-delta_r) + delta_r
   If ((0.25_dp-alphamz*pi/(sqrt2*G_F*mz2*rho*(1._dp-delta_rw))).Lt.0._dp) Then
    kont = -406
    If (Errorlevel.Ge.0) Then
     Write(Errcan,*) "Problem in subroutine "//NameofUnit(Iname)
     Write(Errcan,*) "In the calculation of mW", &
          & 0.25_dp-alphamz*pi/(sqrt2*G_F*mz2*rho*(1._dp-delta_rw))
     Write(errcan,*) "mf_l_mZ, vevSM"
     Write(errcan,*) mf_l_mZ,vevSM
     Write(errcan,*) "mZ2_mZ, dmW2, dmW2_0, rho, delta_rho, sinW2_DR"
     Write(errcan,*) mZ2_mZ, dmW2, dmW2_0, rho, delta_rho, sinW2_DR
     Write(ErrCan,*) "delta_r, cosW2SinW2, delta_rw"
     Write(ErrCan,*) delta_r, cosW2SinW2, delta_rw
    End If
    kont = -411
    Iname = Iname - 1
    Return
   End If
   mW2 = mZ2 * rho * ( 0.5_dp &
      &         +Sqrt(0.25_dp-alphamz*pi/(sqrt2*G_F*mz2*rho*(1._dp-delta_rw))))

   mSpm2(1) = mW2_run ! for this loop
   cosW2 = mW2 / mZ2
   cosW = Sqrt(cosW2)
   sinW2 = 1._dp - cosW2
  End Do
  mSpm2(1) = mW2
  !--------------------------------------------------------------------------
  ! recalcuating m_W and sin^2_W, the formula for m_W is base on Eq.25 of
  ! G.Degrassi et al., NPB351, 49 (1991)  
  !--------------------------------------------------------------------------
  delta_rw = delta_rho*(1._dp-delta_r) + delta_r
  mW2 = mZ2 * rho * ( 0.5_dp &
      &         +Sqrt(0.25_dp-alphamz*pi/(sqrt2*G_F*mz2*rho*(1._dp-delta_rw))))
  mW = Sqrt(mW2)
  cosW2 = mW2 / mZ2
  cosW = Sqrt(cosW2)
  sinW2 = 1._dp - cosW2
  !---------------------------
  ! gauge couplings and vevs
  !---------------------------
  gauge(1) = Sqrt( 4._dp*pi*alphamZ/(1._dp-sinW2_DR) )
  gauge(2) = Sqrt( 4._dp*pi*alphamZ/sinW2_DR)
  gauge(3) = Sqrt( 4._dp*pi*alpha3)
  vev2 =  mZ2_mZ * CosW2SinW2 / (pi * alphamZ)
  vevs_DR(1) = Sqrt(vev2 / (1._dp+tanb**2) )
  vevs_DR(2) = tanb * vevs_DR(1)


  !-------------------------------------
  ! Initialize fermion mixing matrices
  !-------------------------------------
  uU_L = id3C
  uU_R = id3C
  uD_L = id3C
  uD_R = id3C
  uL_L = id3C
  uL_R = id3C
  If (GenerationMixing) Then
   Call Adjungate(CKM, adCKM)
   If (YukawaScheme.Eq.1) Then
    uU_L = CKM
   Else
    uD_L = adCKM
   End If
  End If

  !--------------------------------------------------------------------------
  ! shifting light fermion masses to DR-scheme, only gluon and photon part
  ! except for m_t
  !--------------------------------------------------------------------------
  mf_l_DR_SM = &
    &     mf_l_mZ * (1._dp - oo8pi2 *3._dp *(gauge(1)**2-gauge(2)**2)/16._dp)
  mf_d_DR_SM = mf_d_mZ * (1._dp - alpha3 / (3._dp*pi)                  &
         &               - 23._dp * alpha3**2 / (72._dp * Pi2 )         &
         &               + oo8pi2 * 3._dp * gauge(2)**2 / 16._dp        &
         &               - oo8pi2 * 13._dp * gauge(1)**2 / 144._dp  )
  mf_u_DR_SM(1:2) = mf_u_mZ(1:2)  * (1._dp - alpha3 / (3._dp*pi)       &
         &               - 23._dp * alpha3**2 / (72._dp * Pi2 )         &
         &               + oo8pi2 * 3._dp * gauge(2)**2 / 16._dp        &
         &               - oo8pi2 * 7._dp * gauge(1)**2 / 144._dp  )
  logQ = Log(mZ2/mf_u2(3))
  mf_u_DR_SM(3) = mf_u(3) &
         &          * (1._dp - alpha3 * (5._dp + 3._dp * LogQ                 &
         &                              + (as2loop + log2loop_a * logQ        &
         &                              + log2loop_b * logQ**2) * gauge(3)**2 &
         &                              ) / (3._dp*pi)                        &
         &               - 23._dp * alpha3**2 / (72._dp * Pi2 )               &
         &               + oo8pi2 * 3._dp * gauge(2)**2 / 16._dp              &
         &               - oo8pi2 * 7._dp * gauge(1)**2 / 144._dp  )

!   f_SU3 = 4._dp * gauge(3)**2 / 3._dp
!   If (Resummed) Then ! for small masses a resummation has be done before
!    sumI = 0._dp
!   Else
!    logQ = Log(mZ2/mf_u2(3))
!    sumI = - f_SU3 * mf_u(3) * (5._dp + 3._dp * LogQ               &
!         &                       + (as2loop + log2loop_a * logQ      &
!         &                         + log2loop_b * logQ**2) * gauge(3)**2 )
!   End If
!   If (WriteOut) Write(ErrCan,*) "gluon :",sumI,gsu3
!   res = oo16pi2 * sumI
   !---------------------------------------------------------------------
   ! Yukawa couplings
   !--------------------------------------------------------------------
   Y_d = 0._dp
   Y_u = 0._dp 
   Y_l = 0._dp
   Forall(i1=1:3) Y_u(i1,i1) = sqrt2 * mf_u_DR_SM(i1) / vevs_DR(2)
   Forall(i1=1:3) Y_d(i1,i1) = sqrt2 * mf_d_DR_SM(i1) / vevs_DR(1)
   Forall(i1=1:3) Y_l(i1,i1) = sqrt2 * mf_l_DR_SM(i1) / vevs_DR(1)

   mf_l_DR = mf_l_DR_SM
   mf_d_DR = mf_d_DR_SM
   mf_u_DR = mf_u_DR_SM
   Do i1=1,3
    Y_u(i1,i1) = sqrt2 * mf_u_DR_SM(i1) / vevs_DR(2)
    Y_l(i1,i1) = sqrt2 * mf_l_DR_SM(i1) / vevs_DR(1)
    Y_d(i1,i1) = sqrt2 * mf_d_DR_SM(i1) / vevs_DR(1)
   End Do
   If (GenerationMixing) Then
    If (YukawaScheme.Eq.1) Then
     Y_u = Matmul(Transpose(uU_L),Y_u) 
    Else
     Y_d = Matmul(Transpose(uD_L),Y_d) 
    End If
   End If
   !--------------------------------------------
   ! the starting point of the tree-level mixing
   !--------------------------------------------
   uU_L_T = uU_L
   uU_R_T = uU_R
   uD_L_T = uD_L
   uD_R_T = uD_R
   uL_L_T = uL_L
   uL_R_T = uL_R
   !---------------------------------------------
   ! shifting mixing matrices to superCKM basis 
   !---------------------------------------------
    rot = 0._dp
    rot(1:3,1:3) = Conjg(uU_L_T)
    rot(4:6,4:6) = uU_R_T
    RUsq_ckm = Matmul(RUSquark, Transpose(rot))

    rot = 0._dp
    rot(1:3,1:3) = Conjg(uD_L_T)
    rot(4:6,4:6) = uD_R_T
    RDsq_ckm = Matmul(RDSquark, Transpose(rot))

  converge = .False.

  Y_l_old = Y_l
  Y_d_old = Y_d
  Y_u_old = Y_u
  !------------------------------
  ! now the iteration
  !------------------------------
  Do i_loop =1,100 ! should be sufficient
   yuk_b = Y_d(3,3)! for checking of convergence
   yuk_t = Y_u(3,3)
   yuk_tau = Y_l(3,3)

   If (GenerationMixing) Then
    !---------------------------------------------------------------
    ! rotate squarks from superCKM basis to new electroweak basis
    !---------------------------------------------------------------
    rot = 0._dp
    rot(1:3,1:3) = uU_L_T
    rot(4:6,4:6) = Conjg(uU_R_T)
    RUsq_in = Matmul(RUsq_ckm, rot)
    rot = 0._dp
    rot(1:3,1:3) = uD_L_T
    rot(4:6,4:6) = Conjg(uD_R_T)
    rot = 0._dp
    RDsq_in = Matmul(RDsq_ckm, rot)

    p2 = 0._dp ! for off-diagonal elements
    ! u-quarks
    Call Sigma_Fermion3(p2, mf_u_DR, Y_u, uU_L_T, uU_R_T, gSU2, gSU3, sinW2_DR &
        & , T3_u, e_u, mf_d_DR, Y_d, uD_L_T, uD_R_T, mUSquark2,RUsq_in         &
        & , mDSquark2, RDsq_in, mglu , phase_glu, mN, mN2, N, mC, mC2, U, V   &
        & , mS02, RS0, mP02, RP0, mSpm2 , RSpm, mZ2_run, mW2_run, .True.       &
        & , SigS_u, SigL_u, SigR_u, SigQCD)
    ! d-quarks
    Call Sigma_Fermion3(p2, mf_d_DR, Y_d, uD_L_T, uD_R_T, gSU2, gSU3, sinW2_DR &
        & , T3_d, e_d, mf_u_DR, Y_u, uU_L_T, uU_R_T, mDSquark2, RDsq_in        &
        & , mUSquark2, RUsq_in,  mglu , phase_glu, mN, mN2, N, mC, mC2, U, V   &
        & , mS02, RS0, mP02, RP0, mSpm2 , RSpm, mZ2_run, mW2_run , .True.      &
        & , SigS_d, SigL_d, SigR_d)
    ! leptons
    Call Sigma_Fermion3(p2, mf_l_DR, Y_l, uL_L, uL_R, gSU2, gSU3, sinW2_DR    &
        & , T3_d, e_e, mf_nu, Y_nu, id3C, id3C, mSlepton2, RSlepton           &
        & , mSneutrino2, RSneutrino, mglu , phase_glu, mN, mN2, N, mC, mC2, U &
        & , V, mS02, RS0, mP02, RP0, mSpm2 , RSpm, mZ2_run, mW2_run, .False.  &
        & , SigS_l, SigL_l, SigR_l)

    mf_u_DR_SM(3) = mf_u(3) + SigQCD
    Call Yukawas(mf_u_DR_SM, vevs_DR(2), uU_L, uU_R, SigS_u, SigL_u, SigR_u &
          & , Y_u, .False., kont)

    If (kont.Ne.0) Then
     Iname = Iname - 1
     Return
    End If
    Call Yukawas(mf_d_DR_SM, vevs_DR(1), uD_L, uD_R, SigS_d, SigL_d, SigR_d &
!          & , Y_d, .false., kont)
          & , Y_d, FermionMassResummation, kont)

    If (kont.Ne.0) Then
     Iname = Iname - 1
     Return
    End If
    Call Yukawas(mf_l_DR_SM, vevs_DR(1), id3C, id3C, SigS_l, SigL_l, SigR_l &
          & , Y_l, FermionMassResummation, kont)

    If (kont.Ne.0) Then
     Iname = Iname - 1
     Return
    End If

    !----------------------------------------------------------------
    ! I am only interested in the mixing matrices and, thus, it does
    ! not matter which vev I am using
    !----------------------------------------------------------------
    Call FermionMass(Y_l,vevs_DR(1),mf_l_DR,uL_L_T,uL_R_T,kont)
    Call FermionMass(Y_d,vevs_DR(1),mf_d_DR,uD_L_T,uD_R_T,kont)
    Call FermionMass(Y_u,vevs_DR(2),mf_u_DR,uU_L_T,uU_R_T,kont)

    converge = .True.
    D_mat = Abs(Abs(Y_l) - Abs(Y_l_old))
    Where (Abs(Y_l).Ne.0._dp) D_mat = D_mat / Abs(Y_l)
    Do i1=1,3
     If (D_mat(i1,i1).Gt.0.1_dp*delta0) converge = .False.
     Do i2=i1+1,3
      If (D_mat(i1,i2).Gt.delta0) converge = .False.
      If (D_mat(i2,i1).Gt.delta0) converge = .False.
     End Do
    End Do
    D_mat = Abs(Abs(Y_d) - Abs(Y_d_old))
    Where (Abs(Y_d).Ne.0._dp) D_mat = D_mat / Abs(Y_d)
    Do i1=1,3
     If (D_mat(i1,i1).Gt.0.1_dp*delta0) converge = .False.
     Do i2=i1+1,3
      If (D_mat(i1,i2).Gt.10._dp*delta0) converge = .False.
      If (D_mat(i2,i1).Gt.10._dp*delta0) converge = .False.
     End Do
    End Do
    D_mat = Abs(Abs(Y_u) - Abs(Y_u_old))
    Where (Abs(Y_u).Ne.0._dp) D_mat = D_mat / Abs(Y_u)
    Do i1=1,3
     If (D_mat(i1,i1).Gt.0.1_dp*delta0) converge = .False.
     Do i2=i1+1,3
      If (D_mat(i1,i2).Gt.10._dp*delta0) converge = .False.
      If (D_mat(i2,i1).Gt.10._dp*delta0) converge = .False.
     End Do
    End Do

    If (converge) Exit

    Y_l_old = Y_l
    Y_u_old = Y_u
    Y_d_old = Y_d

  Else ! .not.GenerationMixing
   Do i1=1,3

     p2 = mf_d_DR(i1)**2
     Call Sigma_Fermion(p2, i1, mf_d_DR, Y_d, id3C, id3C,gSU2,gSU3,sinW2_DR   &
      & ,T3_d, e_d, mf_u_DR, Y_u, id3C, id3C, mDSquark2, RDSquark, mUSquark2  &
      & ,RUSquark, mglu, phase_glu, mN, mN2, N, mC, mC2, U, V, mS02, RS0      &
      & ,mP02, RP0, mSpm2, RSpm, mZ2_run, mW2_run, .True., .True., SigDown)
     If (FermionMassResummation) Then
      mf_d_DR(i1) = mf_d_DR_SM(i1) / (1- Real(SigDown,dp) / mf_d_DR(i1) )
     Else
      mf_d_DR(i1) = mf_d_DR_SM(i1) + Real(SigDown,dp)
     End If
     Y_d(i1,i1) = sqrt2 * mf_d_DR(i1) / vevs_DR(1)

     p2 = mf_u_DR(i1)**2
     If (i1.Lt.3) Then
      Call Sigma_Fermion(p2, i1, mf_u_dR, Y_u, id3C, id3C, gSU2, gSU3,sinW2_DR&
        & ,T3_u, e_u, mf_d_DR, Y_d, id3C, id3C,mUSquark2,RUSquark,mDSquark2   &
        & ,RDSquark, mglu, phase_glu, mN, mN2, N, mC, mC2, U, V, mS02, RS0    &
        & ,mP02, RP0, mSpm2, RSpm, mZ2_run, mW2_run, .True., .True., SigUp)
     Else
      Call Sigma_Fermion(p2, i1, mf_u_DR, Y_u, id3C, id3C, gSU2, gSU3,sinW2_DR&
        & ,T3_u, e_u, mf_d_DR, Y_d, id3C, id3C,mUSquark2,RUSquark,mDSquark2   &
        & ,RDSquark, mglu, phase_glu, mN, mN2, N, mC, mC2, U, V, mS02, RS0    &
        & ,mP02, RP0, mSpm2, RSpm, mZ2_run, mW2_run, .True., .False., SigUp)
     End If
     mf_u_DR(i1) = mf_u_DR_SM(i1) + Real(SigUp,dp)
     Y_u(i1,i1) = sqrt2 * mf_u_DR(i1) / vevs_DR(2)

     p2 = mf_l_DR(i1)**2
     Call Sigma_Fermion(p2, i1, mf_l, Y_l, id3C, id3C, gSU2, gSU3, sinW2_DR  &
        & , T3_d, e_e, mf_nu, Y_nu, id3C, id3C, mSlepton2, RSlepton          &
        & , mSneutrino2, RSneutrino, mglu, phase_glu, mN, mN2, N, mC, mC2, U &
        & , V, mS02, RS0, mP02, RP0, mSpm2, RSpm, mZ2_run, mW2_run           &
        & , .False., .True., SigLep)
     If (FermionMassResummation) Then
      mf_l_DR(i1) = mf_l_DR_SM(i1) / (1- Real(SigLep,dp) / mf_l_DR(i1) )
     Else
      mf_l_DR(i1) = mf_l_DR_SM(i1) + Real(SigLep,dp)
     End If
     Y_l(i1,i1)  = sqrt2 * mf_l_DR(i1) / vevs_DR(1)
    
    End Do

    If (    (      Abs((yuk_tau-y_l(3,3))/y_l(3,3)).Lt. 0.1_dp*delta0) &
        &    .And.(Abs((yuk_t-y_u(3,3))  /y_u(3,3)).Lt. 0.1_dp*delta0) &
        &    .And.(Abs((yuk_b-y_d(3,3))  /y_d(3,3)).Lt. 0.1_dp*delta0) ) Then
     converge = .True.
     Exit
    End If
   End If  ! GenerationMixing

   !--------------------------------------------------
   ! Either we have run into a numerical problem or
   ! perturbation theory breaks down
   !--------------------------------------------------

   If (    (Minval(Abs(mf_l_DR/mf_l)).Lt.0.1_dp)  &
     & .Or.(Maxval(Abs(mf_l_DR/mf_l)).Gt.10._dp) ) Then
    Iname = Iname - 1
    kont = -408
    Return
   Else If (    (Minval(Abs(mf_d_DR/mf_d)).Lt.0.1_dp)  &
          & .Or.(Minval(Abs(mf_d_DR/mf_d)).Gt.10._dp) ) Then
    Iname = Iname - 1
    kont = -409
    Return
   Else If (    (Minval(Abs(mf_u_DR/mf_u)).Lt.0.1_dp)  &
          & .Or.(Minval(Abs(mf_u_DR/mf_u)).Gt.10._dp) ) Then
    Iname = Iname - 1
    kont = -410
    Return
   End If

  End Do ! i_loop
!Write(*,*) "i_loop",i_loop

  If (.Not.converge) Then
   Write (ErrCan,*) 'Problem in subroutine BoundaryEW_2!!'
   Write (ErrCan,*) "After",i_loop-1,"iterations no convergence of Yukawas"
   Write (ErrCan,*) 'yuk_tau,yuk_l(3,3)',yuk_tau,y_l(3,3)
   Write (ErrCan,*) 'yuk_b,yuk_d(3,3)',yuk_b,y_d(3,3)
   Write (ErrCan,*) 'yuk_t,yuk_u(3,3)',yuk_t,y_u(3,3)
  End If
!Write(41,*) "h",mp02(2)+mp02(1),ms02(2)+ms02(1),mp02(1)-mz2
!Write(41,*) sqrt(mp02(1)),sqrt(mz2)
  !----------------------------------------------------------------
  ! the RGE paper defines the Yukawas transposed to my conventions
  !----------------------------------------------------------------
  Yl_mZ = Y_l
  Yd_mZ = Y_d
  Yu_mZ = Y_u
  Y_u = Transpose(Y_u)
  Y_d = Transpose(Y_d)
  Y_l = Transpose(Y_l)
  sinW2_DR_mZ = sinW2_DR
  gauge(1) = Sqrt( 5._dp/3._dp) * gauge(1)
  gauge_mZ = gauge

  Call  CouplingsToG(gauge, y_l, y_d, y_u, g1)

  !----------------------------------------------
  ! resetting scale
  !----------------------------------------------
  test = SetRenormalizationScale(test)

  Iname = Iname - 1

 Contains

  Real(dp) Function rho_2(r)
  Implicit None
   Real(dp), Intent(in) :: r
   Real(dp) :: r2, r3
   r2 = r*r
   r3 = r2*r
   rho_2 = 19._dp - 16.5_dp * r + 43._dp * r2 / 12._dp             &
       & + 7._dp * r3 / 120._dp                                    &
       & - Pi * Sqrt(r) * (4._dp - 1.5_dp * r + 3._dp * r2/32._dp  &
       &                  + r3/256._dp)                             &
       & - Pi2 * (2._dp - 2._dp * r + 0.5_dp * r2)                 &
       & - Log(r) * (3._dp * r - 0.5_dp * r2) 
  End  Function rho_2

  Subroutine Yukawas(mf, vev, uL, uR, SigS, SigL, SigR, Y, ReSum, kont)
  !--------------------------------------------------------
  ! solves the matrix equation for Y by a transformation to
  ! a linear system of 9 equations in 9 unknowns
  ! written by Werner Porod, 19.03.03
  !--------------------------------------------------------
  Implicit None
   Integer, Intent(inout) :: kont
   Real(dp), Intent(in) :: mf(3), vev
   Complex(dp), Dimension(3,3), Intent(in) :: uL, uR, SigS, SigL, SigR
   Logical, Intent(in) :: ReSum
   Complex(dp), Intent(inout) :: Y(3,3)

   Integer :: i1
   Complex(dp), Dimension(3,3) :: mass, uLa, uRa, f, invf, invY

   !-------------------------------------
   ! first the mass matrix in DR scheme
   !-------------------------------------
   Call Adjungate(uL, uLa)
   Call Adjungate(uR, uRa)
   mass = ZeroC
   Do i1=1,3
    mass(i1,i1) = mf(i1)
   End Do
   mass = Matmul( Transpose(uL), Matmul(mass, uR) )
   !----------------------------------------
   ! setting up the equations
   !----------------------------------------
   Y = Y * vev * oosqrt2
   If (ReSum) Then
    kont = 0
    Call chop(Y)
    invY = Y
    Call gaussj(kont,invY,3,3)
    If (kont.Ne.0) Return

    f = id3C - Matmul(SigS,invY) - Transpose(SigL) - Matmul(Y,Matmul(SigR,invY))
    invf = f
    Call gaussj(kont,invf,3,3)
    If (kont.Ne.0) Return

    Y = Matmul(invf,mass)

   Else

    Y = mass + SigS + Matmul(Transpose(SigL),Y) + Matmul(Y,SigR)

   End If

   Y = sqrt2 * Y / vev

   Call chop(y)

  End Subroutine Yukawas

 End Subroutine BoundaryEW_2

 Subroutine BoundaryHS(g1,g2)
 !-----------------------------------------------------------------------
 ! calculates the  boundary at th high scale
 ! written by Werner Porod, 28.8.99
 ! last change: 28.8.99
 !     and back, putting in correct thresholds. For the first iteration
 !     only the first 6 couplings are included and a common threshold
 !     is used.
 ! 25.09.01: Portation to f90
 !  - the string scenario A: eqs. (3.11), (3.15) and (3.19)
 !    the string scenario B: eqs. (3.11), (3.16) and (3.20)
 !    from P.Binetruy at al., NPB 604, 32 (2001), hep-ph/0011081
 ! 31.10.02: including AMSB
 ! 06.12.02: including OI model of 
 !           P.Binetruy at al., NPB 604, 32 (2001), hep-ph/0011081
 !       -  Note, that I do have the opposite sign convention concerning
 !          the anomalous dimensions 
 !       - It is assumed that all terms of the form Ln(mu_R) vanish
 !-----------------------------------------------------------------------
  Implicit None

  Real(dp), Intent(in) :: g1(:)
  Real(dp), Intent(out) :: g2(:)

  Real(dp) :: gGMSB, fGMSB, ratio, Mhlf2(3), Mhlf1(3), gauge2(3), gauge4(3), M02
  Integer :: i1, i2, i3, ierr

  Real(dp) :: GammaH1, GammaH2, GammaGE(2,3), GammaGL(2,3), GammaGD(3,3)    &
     & , GammaGU(3,3), GammaGQ(3,3), GammaGH1(3), GammaGH2(3), GammaYH1     &
     & , GammaYH2, LnG2(3), fac, m15(3)
  Complex(dp), Dimension(3,3) :: GammaE, GammaL, GammaD, GammaU, GammaQ     &
     & , GammaYE, GammaYL, GammaYD, GammaYU, GammaYQ, GammaYQu, GammaYQd    &
     & , Ynu, d3, d3a, d3b, Ad, Au, M2D, M2Q, M2U, Yeff, UL, UR
  Complex(dp) :: d1, d2, wert
  Real(dp) :: mf(3)

  Iname = Iname + 1
  NameOfUnit(Iname) = 'BoundaryHS'

  If (Size(g1).Eq.57) Then
   Call GToCouplings(g1, gauge_0, Y_l_0, Y_d_0, Y_u_0)
  Else If (Size(g1).Eq.75) Then
    Call GToCouplings2(g1, gauge_0, Y_l_0, Y_nu_0, Y_d_0, Y_u_0)
  Else If (Size(g1).Eq.79) Then
    Call GToCouplings4(g1, gauge_0, Y_l_0, d3, Y_d_0, Y_u_0, d1, d2)
  Else If (Size(g1).Eq.93) Then
   If (Fixed_Nu_Yukawas) Then ! do not use Y_nu from running but re-use
                              ! the ones given from outside -> dummy argument Ynu
   
    Call GToCouplings3(g1, gauge_0, Y_l_0, Ynu, Y_d_0, Y_u_0, mNuL5)
   Else
    Call GToCouplings3(g1, gauge_0, Y_l_0, Y_nu_0, Y_d_0, Y_u_0, mNuL5)
   End If
  Else If (Size(g1).Eq.118) Then
    Call GToCouplings5(g1, gauge_0, Y_l_0, d3, Y_d_0, Y_u_0, d3a, d3b &
                    & , d1, d2, M15)

  Else
   Write(ErrCan,*) "Error in routine BoundaryHS"
   Write(ErrCan,*) "Size of g1",Size(g1)
   Call TerminateProgram
  End If  

  !--------------------------------------------------
  ! the following models need anomalous dimensions
  !--------------------------------------------------
  If (    (HighScaleModel.Eq.'AMSB').Or.(HighScaleModel.Eq.'Str_A')  &
     &.Or.(HighScaleModel.Eq.'Str_B').Or.(HighScaleModel.Eq.'Str_C') ) Then
   !-------------------------------------
   ! some General Definitions
   !-------------------------------------
   gauge2 = gauge_0**2
   gauge4 = gauge2**2
   GammaYE = oo16pi2 * 2._dp * Matmul( Y_l_0, Conjg(Transpose(Y_l_0)) )
   GammaYL = oo16pi2 * Matmul( Conjg(Transpose(Y_l_0)), Y_l_0 )
   GammaYD = oo16pi2 * 2._dp * Matmul( Y_d_0, Conjg(Transpose(Y_d_0)) )
   GammaYU = oo16pi2 * 2._dp * Matmul( Y_u_0, Conjg(Transpose(Y_u_0)) )
   GammaYQd = oo16pi2 * Matmul( Conjg(Transpose(Y_d_0)), Y_d_0 )
   GammaYQu = oo16pi2 * Matmul( Conjg(Transpose(Y_u_0)), Y_u_0 )
   GammaYQ = GammaYQd + GammaYQu
   !-----------------------------------------------------------------------
   ! anomalous dimension, attention, there are different sign conventions
   ! in the literature
   !------------------------------------------------------------------------
   GammaGH1(1) = - oo16pi2 * 0.3_dp * gauge2(1)
   GammaGH1(2) = - oo16pi2 * 1.5_dp * gauge2(2)
   GammaGH1(3) = 0._dp
   GammaGH2 = GammaGH1
   GammaGE(1,:) = - oo16pi2 * 1.2_dp * gauge2(1) 
   GammaGE(2,:) = 0._dp
   GammaGL(1,:) = GammaGH1(1) 
   GammaGL(2,:) = GammaGH1(2)
   GammaGD(1,:) = - oo16pi2 * 0.4_dp * gauge2(1) / 3._dp
   GammaGD(2,:) = 0._dp
   GammaGD(3,:) = - oo16pi2 * 8._dp * gauge2(3) / 3._dp 
   GammaGU(1,:) = - oo16pi2 * 1.6_dp * gauge2(1) / 3._dp
   GammaGU(2,:) = 0._dp
   GammaGU(3,:) = GammaGD(3,:)
   GammaGQ(1,:) = - oo16pi2 * 0.1_dp * gauge2(1) / 3._dp
   GammaGQ(2,:) = GammaGL(2,:)
   GammaGQ(3,:) = GammaGD(3,:)
 
   GammaH1 =  Sum(GammaGH1)
   GammaH2 = GammaH1
   GammaE = GammaYE 
   GammaL = GammaYL 
   GammaD = GammaYD 
   GammaU = GammaYU 
   GammaQ = GammaYQ 
   Do i1=1,3
    GammaH1 = GammaH1 + 3._dp * GammaYQd(i1,i1) + GammaYL(i1,i1)
    GammaH2 = GammaH2 + 3._dp * GammaYQu(i1,i1) 
    GammaE(i1,i1) = GammaE(i1,i1) + Sum(GammaGE(:,i1))
    GammaL(i1,i1) = GammaL(i1,i1) + Sum(GammaGL(:,i1))
    GammaD(i1,i1) = GammaD(i1,i1) + Sum(GammaGD(:,i1))
    GammaU(i1,i1) = GammaU(i1,i1) + Sum(GammaGU(:,i1))
    GammaQ(i1,i1) = GammaQ(i1,i1) + Sum(GammaGQ(:,i1))
   End Do
   GammaYH1 = GammaH1 - Sum(GammaGH1)
   GammaYH2 = GammaH2 - Sum(GammaGH2)
  End If

  !--------------------------------------------------
  ! now the boundary conditions
  !--------------------------------------------------
  If (HighScaleModel.Eq.'GMSB') Then
   M2_E_0 = ZeroC
   M2_L_0 = ZeroC
   M2_D_0 = ZeroC
   M2_Q_0 = ZeroC
   M2_U_0 = ZeroC

   ratio = Lambda / MlambdaS
   gGMSB = (1._dp+ratio)/ratio**2 * Log(1._dp + ratio)        &
       & + (1._dp-ratio)/ratio**2 * Log(1._dp - ratio)
   fGMSB = (1._dp+ratio)/ratio**2 * ( Log(1._dp + ratio)                &
       &                          - 2._dp * Li2(ratio/(1._dp+ratio) )   &
       &               + 0.5_dp * Li2(2._dp*ratio/(1._dp+ratio) ) )     &
       & + (1._dp-ratio)/ratio**2 * ( Log(1._dp - ratio)                &
       &               - 2._dp * Li2(ratio/(ratio-1._dp) )              &
       &               + 0.5_dp * Li2(2._dp*ratio/(ratio-1._dp) ) )

   Mhlf1 = gauge_0**2 * Lambda * oo16pi2
   Mhlf2 = Mhlf1**2
   Mi_0 = gGMSB * (n5plets + 3*n10plets) * Mhlf1

   If (Off_GMSB) Then
    Mhlf2(1) = 1.000581_dp * Mhlf2(1)
    Mhlf2(2) = 1.000937_dp * Mhlf2(2)
    Mhlf2(3) = 1.00154_dp * Mhlf2(3)
   End If
   M2_H_0 = fGMSB * (n5plets + 3*n10plets)                  &
         &       * ( 1.5_dp * Mhlf2(2) + 0.3_dp * Mhlf2(1) )
   M2_H_0(2) = M2_H_0(1)
   M2_E_0(1,1) = fGMSB * (n5plets + 3*n10plets) * 1.2_dp * Mhlf2(1)
   M2_L_0(1,1) = M2_H_0(1)
   M2_D_0(1,1) = fGMSB * (n5plets + 3*n10plets)              &
         &       * (2._dp / 15._dp * Mhlf2(1) + 8._dp / 3._dp * Mhlf2(3) )
   M2_Q_0(1,1) = fGMSB * (n5plets + 3*n10plets)              &
      &  * (Mhlf2(1) / 30._dp + 1.5_dp * Mhlf2(2) + 8._dp / 3._dp * Mhlf2(3) )
   M2_U_0(1,1) = fGMSB * (n5plets + 3*n10plets)              &
         &       * (8._dp / 15._dp * Mhlf2(1) + 8._dp / 3._dp * Mhlf2(3) )
   Do i1=2,3
    M2_E_0(i1,i1) = M2_E_0(1,1)
    M2_L_0(i1,i1) = M2_L_0(1,1)
    M2_D_0(i1,i1) = M2_D_0(1,1)
    M2_Q_0(i1,i1) = M2_Q_0(1,1)
    M2_U_0(i1,i1) = M2_U_0(1,1)
   End Do

  Else If (HighScaleModel.Eq.'AMSB') Then
   M2_E_0 = ZeroC
   M2_L_0 = ZeroC
   M2_D_0 = ZeroC
   M2_Q_0 = ZeroC
   M2_U_0 = ZeroC
   Mi_0 = ZeroC
   A_l_0 = ZeroC
   A_d_0 = ZeroC
   A_u_0 = ZeroC
   !----------------------------------
   ! gaugino mass parameters 
   !----------------------------------
   Do i1=1,3
    Mi_0(i1) = m_32 * b_1(i1) * gauge2(i1) * oo16pi2
   End Do
   !----------------------------------------
   ! A parameter
   !----------------------------------------
   A_l_0 = ZeroC
   A_d_0 = ZeroC
   A_u_0 = ZeroC

   If (GenerationMixing) Then
    A_l_0 = Y_l_0 * GammaH1 + Matmul(GammaL, Conjg(Transpose(Y_l_0)) ) &
         &               + Matmul(Y_l_0, GammaE)
    A_d_0 = Y_d_0 * GammaH1 + Matmul(GammaQ, Conjg(Transpose(Y_d_0)) ) &
         &               + Matmul(Y_d_0, GammaD)
    A_u_0 = Y_u_0 * GammaH2 + Matmul(GammaQ, Conjg(Transpose(Y_u_0)) ) &
         &               + Matmul(Y_u_0, GammaU)
    A_l_0 = - m_32 * A_l_0
    A_d_0 = - m_32 * A_d_0
    A_u_0 = - m_32 * A_u_0
   Else ! .not. GenerationMixing
    Do i1=1,3
     A_l_0(i1,i1) = - m_32 * Y_l_0(i1,i1) * (GammaL(i1,i1)+GammaE(i1,i1)+GammaH1)
     A_d_0(i1,i1) = - m_32 * Y_d_0(i1,i1) * (GammaQ(i1,i1)+GammaD(i1,i1)+GammaH1)
     A_u_0(i1,i1) = - m_32 * Y_u_0(i1,i1) * (GammaQ(i1,i1)+GammaU(i1,i1)+GammaH2)
    End Do
   End If
   !----------------------------------------
   ! scalar parameters
   !----------------------------------------
   M02 = M0_amsb**2
   If (GenerationMixing) Then
    M2_E_0 = - oo16pi2 * m_32 * ( Matmul( Transpose(Conjg(Y_l_0)), A_l_0)   &
          &                    + Matmul( Transpose(Conjg(A_l_0)), Y_l_0)   )
    M2_D_0 = - oo16pi2 * m_32 * ( Matmul( Transpose(Conjg(Y_d_0)), A_d_0)   &
          &                    + Matmul( Transpose(Conjg(A_d_0)), Y_d_0)   )
    M2_U_0 = - oo16pi2 * m_32 * ( Matmul( Transpose(Conjg(Y_u_0)), A_u_0)   &
          &                    + Matmul( Transpose(Conjg(A_u_0)), Y_u_0)   )
    M2_L_0 = 0.5_dp * Transpose( M2_E_0 )
    M2_Q_0 = 0.5_dp * Transpose( M2_D_0 + M2_U_0 )
    Do i1=1,3
     M2_E_0(i1,i1) = M2_E_0(i1,i1) + M02                                      &
         & - (oo16pi2 * m_32)**2 * 198._dp / 25._dp * gauge4(1)
     M2_L_0(i1,i1) = M2_L_0(i1,i1) + M02                                      &
         & - (oo16pi2 * m_32)**2                                              &
         &               * (99._dp / 50._dp * gauge4(1) + 1.5_dp * gauge4(2))
     M2_D_0(i1,i1) = M2_D_0(i1,i1) + M02                                     &
         & - (oo16pi2 * m_32)**2                                             &
         &               * (22._dp / 25._dp * gauge4(1) - 8._dp * gauge4(3))
     M2_Q_0(i1,i1) = M2_Q_0(i1,i1) + M02                                     &
         & - (oo16pi2 * m_32)**2                                             &
         &          * (11._dp / 50._dp * gauge4(1)  + 1.5_dp * gauge4(2)     &
         &             - 8._dp * gauge4(3))
     M2_U_0(i1,i1) = M2_U_0(i1,i1) + M02                                     &
         & - (oo16pi2 * m_32)**2                                             &
         &               * (88._dp / 25._dp * gauge4(1) - 8._dp * gauge4(3))
    End Do

   Else ! .not. GenerationMixing
    Do i1=1,3
     M2_E_0(i1,i1) = M02                                         &
         & - (oo16pi2 * m_32)**2 * 198._dp / 25._dp * gauge4(1) &
         & - oo16pi2 * m_32 * 2._dp * Y_l_0(i1,i1) * A_l_0(i1,i1)
     M2_L_0(i1,i1) = M02                                                      &
         & - (oo16pi2 * m_32)**2                                              &
         &               * (99._dp / 50._dp * gauge4(1) + 1.5_dp * gauge4(2)) &
         & - oo16pi2 * m_32 * Y_l_0(i1,i1) * A_l_0(i1,i1)
     M2_D_0(i1,i1) = M02                                                      &
         & - (oo16pi2 * m_32)**2                                              &
         &               * (22._dp / 25._dp * gauge4(1) - 8._dp * gauge4(3))  &
         & - oo16pi2 * m_32 * 2._dp * Y_d_0(i1,i1) * A_d_0(i1,i1)
     M2_Q_0(i1,i1) = M02                                                     &
         & - (oo16pi2 * m_32)**2                                             &
         &          * (11._dp / 50._dp * gauge4(1)  + 1.5_dp * gauge4(2)     &
         &             - 8._dp * gauge4(3))                                  &
         & - oo16pi2 * m_32                                                  &
         &       * (Y_d_0(i1,i1) * A_d_0(i1,i1) + Y_u_0(i1,i1) * A_u_0(i1,i1) )
     M2_U_0(i1,i1) = M02                                                      &
         & - (oo16pi2 * m_32)**2                                              &
         &               * (88._dp / 25._dp * gauge4(1) - 8._dp * gauge4(3)) &
         & - oo16pi2 * m_32 * 2._dp * Y_u_0(i1,i1) * A_u_0(i1,i1)
    End Do
   End If

   M2_H_0 = M02                                                             &
       & - (oo16pi2 * m_32)**2                                              &
       &               * (99._dp / 50._dp * gauge4(1) + 1.5_dp * gauge4(2))
   Do i1=1,3
    M2_H_0(1) = M2_H_0(1) - oo16pi2 * m_32 * (3._dp *Y_d_0(i1,i1) *A_d_0(i1,i1) &
             &                             +  Y_l_0(i1,i1) * A_l_0(i1,i1)  )
    M2_H_0(2) = M2_H_0(2) - oo16pi2 * m_32 * 3._dp * Y_u_0(i1,i1) * A_u_0(i1,i1)
   End Do  

  Else If (HighScaleModel.Eq.'Str_A') Then
   !----------------------------------------
   ! Gaugino mass parameter
   !----------------------------------------
   Do i1=1,3
    Mi_0(i1) = sinT * (1 + oo8pi2 * g_s2 * sumC2(i1)) * phase_s * oosqrt_k_ss &
         &   + 2._dp * oo8pi2 * b_1(i1) * oosqrt3
    If (cosT.Ne.0._dp) Then
     Do i2=1,num_t
      Mi_0(i1) = Mi_0(i1)                                   &
          &    + oo8pi2 * cosT * ReG2ThetaT(i2) * phase_t(i2)   &
          &             * (delta_GS + 2._dp*b_1(i1) ) * oosqrt3
     End Do
    End If
    Mi_0(i1) = - 0.5_dp * sqrt3 * gauge2(i1) * m32 * Mi_0(i1)
   End Do
  !----------------------------------------
   ! A parameter
   !----------------------------------------
   AoY_l_0 = ZeroC
   AoY_d_0 = ZeroC
   AoY_u_0 = ZeroC

   wert = - oosqrt3 * k_s * sinT * oosqrt_k_ss 
  
   Do i1=1,3
    AoY_l_0(i1,i1) = -m32 * (GammaL(i1,i1) + GammaE(i1,i1) + GammaH1 + wert)
    AoY_d_0(i1,i1) = -m32 * (GammaQ(i1,i1) + GammaD(i1,i1) + GammaH1 + wert)
    AoY_u_0(i1,i1) = -m32 * (GammaQ(i1,i1) + GammaU(i1,i1) + GammaH2 + wert)
   End Do

   !----------------------------------------
   ! scalar mass parameters
   !----------------------------------------
   M2_E_0 = ZeroC
   M2_L_0 = ZeroC
   M2_D_0 = ZeroC
   M2_Q_0 = ZeroC
   M2_U_0 = ZeroC

   fac = sqrt3 * sinT * oosqrt_k_ss
   Do i1=1,3
    M2_E_0(i1,i1) = sinT2 - GammaE(i1,i1) 
    M2_L_0(i1,i1) = sinT2 - GammaL(i1,i1)
    M2_D_0(i1,i1) = sinT2 - GammaD(i1,i1)
    M2_Q_0(i1,i1) = sinT2 - GammaQ(i1,i1)
    M2_U_0(i1,i1) = sinT2 - GammaU(i1,i1)

   ! sin(Theta) part
    wert = - gauge2(1) * GammaGE(1,i1) * Real( phase_s,dp )            &
     &   + 0.5_dp * GammaYE(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
    M2_E_0(i1,i1) = M2_E_0(i1,i1) + fac * wert

    wert = - ( gauge2(1) * GammaGL(1,i1)                             &
     &       + gauge2(2) * GammaGL(2,i1) ) * Real( phase_s,dp )         &
     &   + 0.5_dp * GammaYL(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
    M2_L_0(i1,i1) = M2_L_0(i1,i1) + fac * wert

    wert = 0._dp
    Do i3=1,3
     wert = wert - gauge2(i3) * GammaGD(i3,i1)
    End Do
    wert = wert * Real( phase_s, dp )                                  &
     &   + 0.5_dp * GammaYD(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
    M2_D_0(i1,i1) = M2_D_0(i1,i1) + fac * wert

    wert = 0._dp
    Do i3=1,3
     wert = wert - gauge2(i3) * GammaGQ(i3,i1)
    End Do
    wert = wert * Real( phase_s, dp )                                    &
     &   + 0.5_dp * GammaYQ(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
    M2_Q_0(i1,i1) = M2_Q_0(i1,i1) + fac * wert

    wert = 0._dp
    Do i3=1,3
     wert = wert - gauge2(i3) * GammaGU(i3,i1)
    End Do
    wert = wert * Real( phase_s, dp )                                     &
     &   + 0.5_dp * GammaYU(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
    M2_U_0(i1,i1) = M2_U_0(i1,i1) + fac * wert

    ! overall part
    M2_E_0(i1,i1) = M2_E_0(i1,i1) * m32**2
    M2_L_0(i1,i1) = M2_L_0(i1,i1) * m32**2
    M2_D_0(i1,i1) = M2_D_0(i1,i1) * m32**2
    M2_Q_0(i1,i1) = M2_Q_0(i1,i1) * m32**2
    M2_U_0(i1,i1) = M2_U_0(i1,i1) * m32**2
   End Do

   M2_H_0(1) = SinT2 - GammaH1
   M2_H_0(2) = SinT2 - GammaH2
   Do i2=1,num_t
   ! sin(Theta) part
    wert = - Real( phase_s, dp )                                                &
     &            * ( gauge2(1) * GammaGH1(1) + gauge2(2) * GammaGH1(2) )   &
     &   + 0.5_dp * GammaYH1 * ( k_s * Conjg(phase_s) + k_sb * phase_s )
    M2_H_0(1) = M2_H_0(1) + fac * wert

    wert = - Real( phase_s,dp )                                         & 
     &   * ( gauge2(1) * GammaGH2(1) + gauge2(2) * GammaGH2(2) )   &
     &   + 0.5_dp * GammaYH2 * ( k_s * Conjg(phase_s) + k_sb * phase_s )
    M2_H_0(2) = M2_H_0(2) + fac * wert

   End Do

   M2_H_0 = M2_H_0 * m32**2

  Else If (HighScaleModel.Eq.'Str_B') Then
   !----------------------------------------
   ! Gaugino mass parameter
   !----------------------------------------
   Do i1=1,3
    Mi_0(i1) = sinT * (1 + oo8pi2 * g_s2 * sumC2(i1)) * phase_s * oosqrt_k_ss &
      &   + 2._dp * oo8pi2 * b_1(i1) * oosqrt3
    If (cosT.Ne.0._dp) Then
     Do i2=1,num_t
      Mi_0(i1) = Mi_0(i1)                                   &
      &    + oo8pi2 * cosT * ReG2ThetaT(i2) * phase_t(i2)   &
      &         * (delta_GS + 2._dp*b_1(i1) ) * oosqrt3
     End Do
    End If
    Mi_0(i1) = - 0.5_dp * sqrt3 * gauge2(i1) * m32 * Mi_0(i1)
   End Do
   !----------------------------------------
   ! A parameter
   !----------------------------------------
   AoY_l_0 = ZeroC
   AoY_d_0 = ZeroC
   AoY_u_0 = ZeroC

   wert = - k_s * sinT * oosqrt_k_ss 
   LnG2 = 0.5_dp * (Log( Gauge2 ) - 1._dp)
   i2 = 1
   Do i1=1,3
    AoY_l_0(i1,i1) = (GammaL(i1,i1) + GammaE(i1,i1) + GammaH1)            &
     &             * (1._dp + cosT * ReG2ThetaT(i2) ) / Sqrt3          &
     &    - sinT * ( (GammaGE(1,i1) + GammaGL(1,i1) +  GammaGH1(1))    &
     &                  * gauge2(1) * ( LnG2(1)  -  LnReDedekind(i2) ) &
     &             + (GammaGL(2,i1) +  GammaGH1(2))                    &
     &                  * gauge2(2) * ( LnG2(2) -  LnReDedekind(i2) )  &
     &             + (GammaYE(i1,i1) + GammaYL(i1,i1) + GammaH1) * k_s &
     &                *  LnReDedekind(i2)                              &
     &             ) * oosqrt_k_ss
    AoY_d_0(i1,i1) = - (GammaQ(i1,i1) + GammaD(i1,i1) + GammaH1)          &
     &             * (1._dp + cosT * ReG2ThetaT(i2) ) / Sqrt3          &
     &    - sinT * ( (GammaGD(1,i1) + GammaGQ(1,i1) +  GammaGH1(1))    &
     &                  * gauge2(1) * ( LnG2(1)  -  LnReDedekind(i2) ) &
     &             + (GammaGQ(2,i1) +  GammaGH1(2))                    &
     &                  * gauge2(2) * ( LnG2(2) -  LnReDedekind(i2) )  &
     &             + (GammaGD(3,i1) +  GammaGQ(3,i1))                  &
     &                  * gauge2(3) * ( LnG2(3) -  LnReDedekind(i2) )  &
     &             + (GammaYD(i1,i1) + GammaYQ(i1,i1) + GammaH1) * k_s &
     &                *  LnReDedekind(i2)                              &
     &             ) * oosqrt_k_ss
    AoY_u_0(i1,i1) = (GammaQ(i1,i1) + GammaU(i1,i1) + GammaH2)         & 
     &             * (1._dp + cosT * ReG2ThetaT(i2) ) / Sqrt3         &
     &    - sinT * ( (GammaGU(1,i1) + GammaGQ(1,i1) +  GammaGH2(1))    &
     &                  * gauge2(1) * ( LnG2(1)  -  LnReDedekind(i2) ) &
     &             + (GammaGQ(2,i1) +  GammaGH2(2))                    &
     &                  * gauge2(2) * ( LnG2(2) -  LnReDedekind(i2) )  &
     &             + (GammaGU(3,i1) +  GammaGQ(3,i1))                  &
     &                  * gauge2(3) * ( LnG2(3) -  LnReDedekind(i2) )  &
     &             + (GammaYU(i1,i1) + GammaYQ(i1,i1) + GammaH2) * k_s &
     &                *  LnReDedekind(i2)                              &
     &             ) * oosqrt_k_ss

    AoY_l_0(i1,i1) = - sqrt3 * m32 * (AoY_l_0(i1,i1) + wert)
    AoY_d_0(i1,i1) = - sqrt3 * m32 * (AoY_d_0(i1,i1) + wert)
    AoY_u_0(i1,i1) = - sqrt3 * m32 * (AoY_u_0(i1,i1) + wert)
   End Do

   !----------------------------------------
   ! scalar mass parameters
   !----------------------------------------
   M2_E_0 = ZeroC
   M2_L_0 = ZeroC
   M2_D_0 = ZeroC
   M2_Q_0 = ZeroC
   M2_U_0 = ZeroC
   M2_H_0 = 0._dp

   If (SinT.Ne.0._dp) Then
    i2=1
    LnG2 = Log( Gauge2 )
    Do i1=1,3
     ! sin(Theta) part
     fac = sqrt3 * sinT *  oosqrt_k_ss * (1._dp + cosT * ReG2ThetaT(i2) )
     wert = - gauge2(1) * GammaGE(1,i1) * Real( phase_s, dp )            &
      &   + 0.5_dp * GammaYE(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_E_0(i1,i1) = fac * wert

     wert = - ( gauge2(1) * GammaGL(1,i1)                            &
      &        + gauge2(2) * GammaGL(2,i1) ) * Real( phase_s,dp )         &
      &   + 0.5_dp * GammaYL(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_L_0(i1,i1) = fac * wert

     wert = 0._dp
     Do i3=1,3
      wert = wert - gauge2(i3) * GammaGD(i3,i1)
     End Do
     wert = wert * Real( phase_s, dp )                                   &
      &   + 0.5_dp * GammaYD(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_D_0(i1,i1) = M2_D_0(i1,i1) + fac * wert

     wert = 0._dp
     Do i3=1,3
      wert = wert - gauge2(i3) * GammaGQ(i3,i1)
     End Do
     wert = wert * Real( phase_s, dp )                                    &
      &   + 0.5_dp * GammaYQ(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_Q_0(i1,i1) = M2_Q_0(i1,i1) + fac * wert

     wert = 0._dp
     Do i3=1,3
      wert = wert - gauge2(i3) * GammaGU(i3,i1)
     End Do
     wert = wert * Real( phase_s, dp )                                     &
      &   + 0.5_dp * GammaYU(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_U_0(i1,i1) = M2_U_0(i1,i1) + fac * wert

     ! sin(Theta)^2  part
     wert = 1._dp - GammaE(i1,i1)                                      &
       & + GammaGE(1,i1) * (LnG2(1) -  LnReDedekind(i2))               &
       & + 2._dp * GammaYE(i1,i1) * LnReDedekind(i2)                   &
       & + ( 2.25_dp * gauge4(1) * GammaGE(1,i1)                       &
       &             * ( LnG2(1) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 3._dp * GammaYE(i1,i1) * k_s * k_sb * LnReDedekind(i2)    &
       &   )   / k_ss
     M2_E_0(i1,i1) = M2_E_0(i1,i1) + SinT2 * wert

     wert = 1._dp - GammaL(i1,i1)                                      &
       & + GammaGL(1,i1) * (LnG2(1) -  LnReDedekind(i2))               &
       & + GammaGL(2,i1) * (LnG2(2) -  LnReDedekind(i2))               &
       & + 2._dp * GammaYL(i1,i1) * LnReDedekind(i2)                   &
       & + ( 2.25_dp * gauge4(1) * GammaGL(1,i1)                       &
       &             * ( LnG2(1) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 2.25_dp * gauge4(2) * GammaGL(2,i1)                       &
       &             * ( LnG2(2) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 3._dp * GammaYL(i1,i1) * k_s * k_sb * LnReDedekind(i2)    &
       &   )   / k_ss
     M2_L_0(i1,i1) = M2_L_0(i1,i1) + SinT2 * wert

     wert = 1._dp - GammaD(i1,i1)                                      &
       & + GammaGD(1,i1) * (LnG2(1) -  LnReDedekind(i2))               &
       & + GammaGD(3,i1) * (LnG2(3) -  LnReDedekind(i2))               &
       & + 2._dp * GammaYD(i1,i1) * LnReDedekind(i2)                   &
       & + ( 2.25_dp * gauge4(1) * GammaGD(1,i1)                       &
       &             * ( LnG2(1) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 2.25_dp * gauge4(3) * GammaGD(3,i1)                       &
       &             * ( LnG2(3) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 3._dp * GammaYD(i1,i1) * k_s * k_sb * LnReDedekind(i2)    &
       &   )   / k_ss
     M2_D_0(i1,i1) = M2_D_0(i1,i1) + SinT2 * wert

     wert = 1._dp - GammaU(i1,i1)                                      &
       & + GammaGU(1,i1) * (LnG2(1) -  LnReDedekind(i2))               &
       & + GammaGU(3,i1) * (LnG2(3) -  LnReDedekind(i2))               &
       & + 2._dp * GammaYU(i1,i1) * LnReDedekind(i2)                   &
       & + ( 2.25_dp * gauge4(1) * GammaGU(1,i1)                       &
       &             * ( LnG2(1) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 2.25_dp * gauge4(3) * GammaGU(3,i1)                       &
       &             * ( LnG2(3) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 3._dp * GammaYU(i1,i1) * k_s * k_sb * LnReDedekind(i2)    &
       &   )   / k_ss
     M2_U_0(i1,i1) = M2_U_0(i1,i1) + SinT2 * wert

     wert = 1._dp - GammaQ(i1,i1)                                      &
       & + GammaGQ(1,i1) * (LnG2(1) -  LnReDedekind(i2))               &
       & + GammaGQ(2,i1) * (LnG2(2) -  LnReDedekind(i2))               &
       & + GammaGQ(3,i1) * (LnG2(3) -  LnReDedekind(i2))               &
       & + 2._dp * GammaYQ(i1,i1) * LnReDedekind(i2)                   &
       & + ( 2.25_dp * gauge4(1) * GammaGQ(1,i1)                       &
       &             * ( LnG2(1) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 2.25_dp * gauge4(2) * GammaGQ(2,i1)                       &
       &             * ( LnG2(2) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 2.25_dp * gauge4(3) * GammaGQ(3,i1)                       &
       &             * ( LnG2(3) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 3._dp * GammaYQ(i1,i1) * k_s * k_sb * LnReDedekind(i2)    &
       &   )   / k_ss
     M2_Q_0(i1,i1) = M2_Q_0(i1,i1) + SinT2 * wert

     ! overall part
     M2_E_0(i1,i1) = M2_E_0(i1,i1) * m32**2
     M2_L_0(i1,i1) = M2_L_0(i1,i1) * m32**2
     M2_D_0(i1,i1) = M2_D_0(i1,i1) * m32**2
     M2_Q_0(i1,i1) = M2_Q_0(i1,i1) * m32**2
     M2_U_0(i1,i1) = M2_U_0(i1,i1) * m32**2
    End Do

    Do i2=1,num_t
     fac = sqrt3 * sinT *  oosqrt_k_ss * (1._dp + cosT * ReG2ThetaT(i2) )
    ! sin(Theta) part
     wert = - Real( phase_s, dp )                                            &
      &            * ( gauge2(1) * GammaGH1(1) + gauge2(2) * GammaGH1(2) )   &
      &   + 0.5_dp * GammaYH1 * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_H_0(1) = M2_H_0(1) + fac * wert

     wert = - Real( phase_s, dp )                                         & 
      &   * ( gauge2(1) * GammaGH2(1) + gauge2(2) * GammaGH2(2) )   &
      &   + 0.5_dp * GammaYH2 * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_H_0(2) = M2_H_0(2) + fac * wert

     ! sin(Theta)^2  part
     wert = 1._dp - GammaH1                                            &
       & + GammaGH1(1) * (LnG2(1) -  LnReDedekind(i2))                 &
       & + GammaGH1(2) * (LnG2(2) -  LnReDedekind(i2))                 &
       & + 2._dp * GammaYH1 * LnReDedekind(i2)                         &
       & + ( 2.25_dp * gauge4(1) * GammaGH1(1)                         &
       &             * ( LnG2(1) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 2.25_dp * gauge4(2) * GammaGH1(2)                         &
       &             * ( LnG2(2) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 3._dp * GammaYH1 * k_s * k_sb * LnReDedekind(i2)          &
       &   )   / k_ss
     M2_H_0(1) = M2_H_0(1) + SinT2 * wert

     wert = 1._dp - GammaH2                                            &
       & + GammaGH2(1) * (LnG2(1) -  LnReDedekind(i2))                 &
       & + GammaGH2(2) * (LnG2(2) -  LnReDedekind(i2))                 &
       & + 2._dp * GammaYH2 * LnReDedekind(i2)                         &
       & + ( 2.25_dp * gauge4(1) * GammaGH2(1)                         &
       &             * ( LnG2(1) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 2.25_dp * gauge4(2) * GammaGH2(2)                         &
       &             * ( LnG2(2) + 5._dp / 3._dp + LnReDedekind(i2) )  &
       &   + 3._dp * GammaYH2 * k_s * k_sb * LnReDedekind(i2)          &
       &   )   / k_ss
     M2_H_0(2) = M2_H_0(2) + SinT2 * wert
    End Do

    M2_H_0 = M2_H_0 * m32**2
   End If ! SinT.ne.0._dp

  Else If (HighScaleModel.Eq.'Str_C') Then
   !----------------------------------------
   ! Gaugino mass parameter
   !----------------------------------------
   fac = oosqrt_k_ss * sqrt3
   Do i1=1,3
    Mi_0(i1) = sinT * (1._dp + oo8pi2 * g_s2 * sumC2(i1)) * phase_s * fac  &
           & + 2._dp * oo8pi2 * b_1(i1)
    If (cosT.Ne.0._dp) Then
     Do i2=1,num_t
      Mi_0(i1) = Mi_0(i1) + oo8pi2 * cosT * ReG2ThetaT(i2) * phase_t(i2)   &
            &         * (delta_GS + 2._dp * (b_1(i1) - SumC_O1(i1)) )
     End Do
    End If
    Mi_0(i1) = - 0.5_dp * gauge2(i1) * m32 * Mi_0(i1)
   End Do
   !----------------------------------------
   ! A parameter
   !----------------------------------------
   AoY_l_0 = ZeroC
   AoY_d_0 = ZeroC
   AoY_u_0 = ZeroC

   wert = - k_s * sinT * oosqrt_k_ss * sqrt3
   i2 = 1
   fac = cosT * ReG2ThetaT(i2)

   Do i1=1,3
    AoY_l_0(i1,i1) = GammaL(i1,i1) + GammaE(i1,i1) + GammaH1
    AoY_d_0(i1,i1) = GammaQ(i1,i1) + GammaD(i1,i1) + GammaH1
    AoY_u_0(i1,i1) = GammaQ(i1,i1) + GammaU(i1,i1) + GammaH2
    If (cosT.Ne.0._dp) Then
     AoY_l_0(i1,i1) = AoY_l_0(i1,i1)                                    &
               & + fac * (nE_ai(i2,i1) + nL_ai(i2,i1) + nH1_ai(i2) +3)
     AoY_d_0(i1,i1) = AoY_d_0(i1,i1)                                    &
               & + fac * (nD_ai(i2,i1) + nQ_ai(i2,i1) + nH1_ai(i2) +3)
     AoY_u_0(i1,i1) = AoY_u_0(i1,i1)                                    &
               & + fac * (nU_ai(i2,i1) + nQ_ai(i2,i1) + nH2_ai(i2) +3)
    End If

    AoY_l_0(i1,i1) = - m32 * (AoY_l_0(i1,i1) + wert)
    AoY_d_0(i1,i1) = - m32 * (AoY_d_0(i1,i1) + wert)
    AoY_u_0(i1,i1) = - m32 * (AoY_u_0(i1,i1) + wert)
   End Do

   !----------------------------------------
   ! scalar mass parameters
   !----------------------------------------
   M2_E_0 = ZeroC
   M2_L_0 = ZeroC
   M2_D_0 = ZeroC
   M2_Q_0 = ZeroC
   M2_U_0 = ZeroC
   M2_H_0 = 0._dp

   i2=1
   fac = sqrt3 * sinT * oosqrt_k_ss
   Do i1=1,3
     wert = - gauge2(1) * GammaGE(1,i1) * Real( phase_s, dp)    &
        & + 0.5_dp * GammaYE(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_E_0(i1,i1) = fac * wert                                         &
             &    + cosT * ReG2ThetaT(1) *  GammaYE(i1,i1)             &
             &           * (nE_ai(1,i1) + nL_ai(1,i1) + nH1_ai(1) +3)  &
             &    + CosT2 * nE_ai(1,i1)

     wert = - gauge2(1) * GammaGL(1,i1) * Real( phase_s, dp)    &
        & - gauge2(2) * GammaGL(2,i1) * Real( phase_s, dp)      &
        & + 0.5_dp * GammaYL(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_L_0(i1,i1) = fac * wert                                         &
             &    + cosT * ReG2ThetaT(1) *  GammaYL(i1,i1)             &
             &           * (nE_ai(1,i1) + nL_ai(1,i1) + nH1_ai(1) +3)  &
             &    + CosT2 * nL_ai(1,i1)

     wert = - gauge2(1) * GammaGD(1,i1) * Real( phase_s, dp)    &
        & - gauge2(3) * GammaGD(3,i1) * Real( phase_s, dp)      &
        & + 0.5_dp * GammaYD(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_D_0(i1,i1) = fac * wert                                         &
             &    + cosT * ReG2ThetaT(1) *  GammaYD(i1,i1)             &
             &           * (nD_ai(1,i1) + nQ_ai(1,i1) + nH1_ai(1) +3)  &
             &    + CosT2 * nD_ai(1,i1)

     wert = - gauge2(1) * GammaGQ(1,i1) * Real( phase_s, dp)    &
        & - gauge2(2) * GammaGQ(2,i1) * Real( phase_s, dp)      &
        & - gauge2(3) * GammaGQ(3,i1) * Real( phase_s, dp)      &
        & + 0.5_dp * GammaYQ(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_Q_0(i1,i1) = fac * wert                                         &
             &    + cosT * ReG2ThetaT(1) *  GammaYQd(i1,i1)             &
             &           * (nD_ai(1,i1) + nQ_ai(1,i1) + nH1_ai(1) +3)  &
             &    + cosT * ReG2ThetaT(1) *  GammaYQu(i1,i1)             &
             &           * (nU_ai(1,i1) + nQ_ai(1,i1) + nH2_ai(1) +3)  &
             &    + CosT2 * nQ_ai(1,i1)

     wert = - gauge2(1) * GammaGU(1,i1) * Real( phase_s, dp)    &
        & - gauge2(3) * GammaGU(3,i1) * Real( phase_s, dp)      &
        & + 0.5_dp * GammaYU(i1,i1) * ( k_s * Conjg(phase_s) + k_sb * phase_s )
     M2_U_0(i1,i1) = fac * wert                                         &
             &    + cosT * ReG2ThetaT(1) *  GammaYU(i1,i1)             &
             &           * (nU_ai(1,i1) + nQ_ai(1,i1) + nH2_ai(1) +3)  &
             &    + CosT2 * nU_ai(1,i1)

    ! overall part
    M2_E_0(i1,i1) = ( 1._dp + GammaE(i1,i1) + M2_E_0(i1,i1)) * m32**2
    M2_L_0(i1,i1) = ( 1._dp + GammaL(i1,i1) + M2_L_0(i1,i1)) * m32**2
    M2_D_0(i1,i1) = ( 1._dp + GammaD(i1,i1) + M2_D_0(i1,i1)) * m32**2
    M2_Q_0(i1,i1) = ( 1._dp + GammaQ(i1,i1) + M2_Q_0(i1,i1)) * m32**2
    M2_U_0(i1,i1) = ( 1._dp + GammaU(i1,i1) + M2_U_0(i1,i1)) * m32**2
   End Do

   Do i2=1,num_t
     wert = - gauge2(1) * GammaGH1(1) * Real( phase_s, dp)    &
        & - gauge2(2) * GammaGH1(2) * Real( phase_s, dp)      &
        & + 0.5_dp * GammaYH1 * ( k_s * Conjg(phase_s) + k_sb * phase_s )

     M2_H_0(1) = sqrt3 * sinT * wert * oosqrt_k_ss
     wert = 0._dp
     Do i1=1,3
      wert = wert + GammaYL(i1,i1) * (nE_ai(1,i1)+nL_ai(1,i1)+nH1_ai(1)+3) &
        &  + 3._dp * GammaYD(i1,i1) * (nD_ai(1,i1)+nQ_ai(1,i1)+nH1_ai(1)+3)
     End Do
     M2_H_0(1) = M2_H_0(1) + cosT * ReG2ThetaT(1) * wert + CosT2 * nH1_ai(1) 

     wert = - gauge2(1) * GammaGH2(1) * Real( phase_s, dp)    &
        & - gauge2(2) * GammaGH2(2) * Real( phase_s, dp)      &
        & + 0.5_dp * GammaYH2 * ( k_s * Conjg(phase_s) + k_sb * phase_s )

     M2_H_0(2) = sqrt3 * sinT * wert * oosqrt_k_ss
     wert = 0._dp
     Do i1=1,3
      wert = wert &
        &  + 3._dp * GammaYU(i1,i1) * (nU_ai(1,i1)+nQ_ai(1,i1)+nH2_ai(1)+3)
     End Do
     M2_H_0(2) = M2_H_0(2) + cosT * ReG2ThetaT(1) * wert + CosT2 * nH2_ai(1) 

   End Do

   M2_H_0(1) = (1._dp + GammaH1 + M2_H_0(1)) * m32**2
   M2_H_0(2) = (1._dp + GammaH2 + M2_H_0(2)) * m32**2

  End If  ! end of different models

  If (HighScaleModel.Eq.'Oscar') Then
   A_l_0 = AoY_l_0 * Y_l_0
   A_d_0 = Matmul(AoY_q_0, Y_d_0) + Matmul(Y_d_0, AoY_d_0)
   A_u_0 = Matmul(AoY_q_0, Y_u_0) + Matmul(Y_u_0, AoY_u_0)
  Else If (HighScaleModel.Eq.'AMSB') Then 
   AoY_l_0 = 0._dp
   AoY_d_0 = 0._dp
   AoY_u_0 = 0._dp
   Where(Abs(Y_l_0).Ne.0._dp) AoY_l_0 = A_l_0 / Y_l_0
   Where(Abs(Y_d_0).Ne.0._dp) AoY_d_0 = A_d_0 / Y_d_0
   Where(Abs(Y_u_0).Ne.0._dp) AoY_u_0 = A_u_0 / Y_u_0
  Else 
   !------------------------------------------------------
   ! check if parameters in the super CKM basis are given 
   !------------------------------------------------------
   If (l_Ad.Or.l_Au.Or.l_Al.Or.l_ME.Or.l_ML.Or.l_MD.Or.l_MQ.Or.l_MU) &
    & Call Switch_from_superCKM(Y_d_0, Y_u_0, Ad_sckm, Au_sckm, M2D_sckm   &
                      &, M2Q_sckm, M2U_sckm, Ad, Au, M2D, M2Q, M2U, .True. )

   If (.Not.l_Ad) A_l_0 = AoY_l_0 * Y_l_0
   If (l_Ad) Then
    A_d_0 = Ad
   Else
    A_d_0 = AoY_d_0 * Y_d_0
   End If
   If (l_Au) Then
    A_u_0 = Au
   Else
    A_u_0 = AoY_u_0 * Y_u_0
   End If
   If (l_MD) M2_D_0 = M2D
   If (l_MQ) M2_Q_0 = M2Q
   If (l_MU) M2_U_0 = M2U
  End If

  mu_0 = 0._dp
  B_0 = 0._dp

  If (Size(g2).Eq.213) Then
   Call ParametersToG(gauge_0, Y_l_0, Y_d_0, Y_u_0, Mi_0, A_l_0, A_d_0, A_u_0 &
          & , M2_E_0, M2_L_0, M2_D_0, M2_Q_0, M2_U_0, M2_H_0, mu_0, B_0, g2)
  Else If (Size(g2).Eq.267) Then
   If (Ynu_eq_Yu)  Y_nu_0 =  Y_u_0
   A_nu_0 = AoY_nu_0 * Y_nu_0
   Call ParametersToG2(gauge_0, y_l_0, Y_nu_0, y_d_0, y_u_0, Mi_0, A_l_0 &
      & , A_nu_0, A_d_0, A_u_0, M2_E_0, M2_L_0, M2_R_0, M2_D_0, M2_Q_0   &
      & , M2_U_0, M2_H_0, mu_0, B_0, g2)
  Else If (Size(g2).Eq.277) Then
   Call FermionMass(Transpose(Y_l), 1._dp, mf, UL, UR, ierr)
   UL = Conjg(UL)
   Yeff = Matmul(UL,Matmul(Y_T_0,Transpose(UL)))
   A_T_0 = AoT_0 * Yeff
   Alam12_0 = Aolam12_0 * lam12_0
   Call ParametersToG4(gauge_0, y_l_0, Yeff, y_d_0, y_u_0, lam12_0(1)  &
      & , lam12_0(2), Mi_0, A_l_0, A_T_0, A_d_0, A_u_0, Alam12_0(1)     &
      & , Alam12_0(2), M2_E_0, M2_L_0, M2_D_0, M2_Q_0   &
      & , M2_U_0, M2_H_0, M2_T_0, mu_0, B_0, MnuL5, g2)
  Else If (Size(g2).Eq.285) Then
   If (Ynu_eq_Yu)  Y_nu_0 =  Y_u_0
   A_nu_0 = AoY_nu_0 * Y_nu_0
   Call ParametersToG3(gauge_0, y_l_0, Y_nu_0, y_d_0, y_u_0, Mi_0, A_l_0 &
      & , A_nu_0, A_d_0, A_u_0, M2_E_0, M2_L_0, M2_R_0, M2_D_0, M2_Q_0   &
      & , M2_U_0, M2_H_0, mu_0, B_0, MnuL5, g2)
  Else If (Size(g2).Eq.356) Then
   Call FermionMass(Transpose(Y_l), 1._dp, mf, UL, UR, ierr)
   UL = Conjg(UL)
   Yeff = Matmul(UL,Matmul(Y_T_0,Transpose(UL)))
   A_T_0 = AoT_0 * Yeff
   Alam12_0 = Aolam12_0 * lam12_0
   Call ParametersToG5(gauge_0, y_l_0, Yeff, y_d_0, y_u_0, Yeff, Yeff     &
      & , lam12_0(1), lam12_0(2), Mi_0, A_l_0, A_T_0, A_d_0, A_u_0, A_T_0 &
      & , A_T_0, Alam12_0(1), Alam12_0(2), M2_E_0, M2_L_0, M2_D_0, M2_Q_0 &
      & , M2_U_0, M2_H_0, M2_T_0, M2_T_0, M2_T_0, M15(1), M15(1), M15(1)  &
      & , mu_0, B_0, MnuL5, g2)
  Else 
   Write(ErrCan,*) "Error in routine BoundaryHS"
   Write(ErrCan,*) "Size of g2",Size(g2)
   Call TerminateProgram
  End If

  Iname = Iname - 1

 End Subroutine BoundaryHS

 Subroutine FirstGuess(phase_mu, tanb, Mi, M_E2, M_L2, A_e, M_D2 &
                    & , M_Q2, M_U2, A_d, A_u, mu, BImu, M_H2, gU1, gSU2 &
                    & , Y_l, Y_d, Y_u, vevs, mP02, mP0, kont)
 !-----------------------------------------------------------------------
 ! calculates approximate values of the electroweak MSSM parameters,
 ! saving one run of subroutine sugra by running 1-loop RGEs
 ! written by Werner Porod,  08.10.01
 !-----------------------------------------------------------------------
 Implicit None

  Complex(dp), Intent(in) :: phase_mu
  Real(dp), intent(in) :: tanb
  Complex(dp), Intent(out) :: Mi(3), M_E2(3,3), M_L2(3,3), A_e(3,3)           &
     & , M_D2(3,3), M_Q2(3,3), M_U2(3,3), A_d(3,3), A_u(3,3)                  &
     & , mu, BImu, Y_l(3,3), Y_d(3,3), Y_u(3,3)
  Real(dp), Intent(out) :: M_H2(2), mP02(2), mP0(2), gSU2, gU1, vevS(2)

  Real(dp) :: sinb2, cosb2, abs_mu2, abs_mu
  Integer :: i1, i2, kont

  Real(dp) :: gauge(3), vev, g1(57), g0(213), mgut, mudim, sigma(2), mt, mb &
    & , mSup(2), mSup2(2), mSdown(2), mSdown2(2), id2R(2,2),  a0m           &
    & , cosW, cosW2, sinW2
  Real(dp), Parameter ::    e_d = -1._dp / 3._dp,  e_u = -2._dp * e_d 

  Complex(dp) :: RSup(2,2), RSdown(2,2), coupC
  Logical :: TwoLoopRGE_save

  Iname = Iname + 1
  NameOfUnit(Iname) = "FirstGuess"

 !---------
 ! W-boson, first rough estimate
 !---------
  mW2 = mZ2 * (0.5_dp + Sqrt(0.25_dp-Alpha_Mz*pi / (sqrt2*G_F*mZ2))) / 0.985_dp

  mW = Sqrt(mW2)      ! mass
  cosW2 = mw2 / mZ2
  sinW2 = 1._dp - cosW2
  cosW = Sqrt(cosW2)

  gauge(1) = Sqrt( 20._dp*pi*alpha_mZ/(3._dp*(1._dp-sinW2)) )
  gauge(2) = Sqrt( 4._dp*pi*alpha_mZ/sinW2)
  gauge(3) = Sqrt( 4._dp*pi*alphas_mZ)

  vev =  2._dp * mW / gauge(2)
  vevs(1) = vev / Sqrt(1._dp + tanb**2)
  vevs(2) = tanb * vevs(1)

  Y_l = 0._dp
  Y_d = 0._dp
  Y_u = 0._dp
  Do i1=1,3
   y_l(i1,i1) = sqrt2 * mf_L_mZ(i1) / vevS(1)
   if (i1.eq.3) then ! top and bottom are special
    y_u(i1,i1) = sqrt2 * mf_U(i1)  / vevS(2) &
               & * (1._dp - oo3pi *alphas_mZ *(5._dp +3._dp*Log(mZ2/mf_u2(3))))
    y_d(i1,i1) = sqrt2 * mf_D_mZ(i1) / ( vevS(1) * (1._dp+0.015*tanb*phase_mu))
   else
    y_u(i1,i1) = sqrt2 * mf_U_mZ(i1) / vevS(2)
    y_d(i1,i1) = sqrt2 * mf_D_mZ(i1) / vevS(1)
   end if
  End Do

  If (GenerationMixing) then
   If (YukawaScheme.eq.1) then
    Y_u = Matmul(Transpose(CKM),Y_u)
    Y_u = Transpose(Y_u)
   Else
    Y_d = Matmul(Conjg(CKM),Y_d)
    Y_d = Transpose(Y_d)
   End If
  End If
   
  Call  CouplingsToG(gauge, y_l, y_d, y_u, g1)
  TwoLoopRGE_save = TwoLoopRGE

  If (.not.UseFixedScale) then
   mudim =  0.5_dp*Abs(M2_U_0(3,3)+M2_Q_0(3,3))+4._dp*Abs(Mi_0(3))**2
   mudim = Max(mf_u2(3),mudim) 
   call SetRGEScale(mudim)
   UseFixedScale = .False.
  else
   mudim = GetRenormalizationScale() ! from LoopFunctions
  end if

  TwoLoopRGE = .False.

  kont = 0
  Call RunRGE(kont, 0.001_dp, vevS, g1, g0, mGUT)

  TwoLoopRGE = TwoLoopRGE_save

   If (kont.Ne.0) Then
    Write(*,*) "Initialization failed, please send the input files used to"
    Write(*,*) "porod@physik.unizh.ch so that the problem can be analized"
    Write(*,*) "kont",kont
    Iname = Iname - 1
    Return
   End If

   Call GToParameters(g0, gauge, Y_l, Y_d, Y_u, Mi, A_e, A_d, A_u &
                  & , M_E2, M_L2, M_D2, M_Q2, M_U2, M_H2, mu, BiMu)
   Y_u = Transpose(Y_u)
   Y_d = Transpose(Y_d)
   Y_l = Transpose(Y_l)
   A_u = Transpose(A_u)
   A_d = Transpose(A_d)
   A_e = Transpose(A_e)
   M_E2 = Transpose(M_E2)
!   M_L2 = Transpose(M_L2)
   M_D2 = Transpose(M_D2)
   M_U2 = Transpose(M_U2)
!   M_Q2 = Transpose(M_Q2)

   cosb2 = 1._dp / (1._dp + tanb**2)
   sinb2 = cosb2 * tanb**2
   abs_mu2 = (M_H2(2)*sinb2 - M_H2(1)*cosb2)/(cosb2-sinb2) - 0.5_dp * mZ2
   !--------------------------------------------------------------
   ! in some scenarios the tree-level result is not reliable
   ! trying thus a guess for |mu|^2 by reversing the sign
   ! is needed to include 1-loop effective potential method
   !--------------------------------------------------------------
   If (abs_mu2.Lt.0._dp) abs_mu2 = - abs_mu2
   abs_mu = Sqrt(abs_mu2)
   mu = abs_mu * phase_mu
   !--------------------------------------------------------------------------
   ! now the one-loop corrections, have to be taken with care if abs_mu2 had
   ! had been negative before; using only (s)top and (s)bottom Yukawa
   ! corrections
   !-------------------------------------------------------------------------
   mb = abs(Y_d(3,3)) * vevS(1) / sqrt2
   mt = abs(Y_u(3,3)) * vevS(2) / sqrt2
   id2R = 0._dp
   id2R(1,1) = 1._dp
   id2R(2,2) = 1._dp
   Call SfermionMass(Real(M_Q2(3,3),dp), Real(M_U2(3,3),dp),A_u(3,3),mu,vevs  &
     & , Y_u(3,3), 0.5_dp, 1._dp / 3._dp, -4._dp / 3._dp, 0._dp, 0._dp, kont &
     &, mSup, mSup2, Rsup)
   Call SfermionMass(Real(M_Q2(3,3),dp),Real(M_D2(3,3),dp), A_d(3,3), mu, vevs&
     & , Y_d(3,3), -0.5_dp, 1._dp / 3._dp, 2._dp / 3._dp, 0._dp, 0._dp, kont &
     &, mSdown, mSdown2, RSdown)
   sigma(1) = - 2._dp * sqrt2 * mb * Real(Y_d(3,3),dp) * my_a0(mb**2) 
   sigma(2) = - 2._dp * sqrt2 * mt * Real(Y_u(3,3),dp) * my_a0(mt**2)

   Do i2 =1,2
    A0m = my_A0( mSup2(i2) )
    Call CoupScalarSfermion3(1, i2, i2, id2R, 0.5_dp, e_u, Y_u(3,3) &
                         &, Rsup, A_u(3,3), mu, vevs, 0._dp, 0._dp, coupC )
    sigma(1) = sigma(1) - coupC * A0m
    Call CoupScalarSfermion3(2, i2, i2, id2R, 0.5_dp, e_u, Y_u(3,3) &
                           &, Rsup, A_u(3,3), mu, vevs, 0._dp, 0._dp, coupC )
    sigma(2) = sigma(2) - coupC * A0m
   End Do
   Do i2 =1,2
    A0m = my_A0( mSdown2(i2) )
    Call CoupScalarSfermion3(1, i2, i2, id2R, -0.5_dp, e_d, Y_d(3,3) &
                         &, Rsdown, A_d(3,3), mu, vevs, 0._dp, 0._dp, coupC )
    sigma(1) = sigma(1) - coupC * A0m
    Call CoupScalarSfermion3(2, i2, i2, id2R, -0.5_dp, e_d, Y_d(3,3) &
                         &, Rsdown, A_d(3,3), mu, vevs, 0._dp, 0._dp, coupC )
    sigma(2) = sigma(2) - coupC * A0m
   End Do

   sigma = 3._dp * oo16pi2 * sigma / vevs 

   abs_mu2 = ((M_H2(2)-sigma(2))*sinb2 - (M_H2(1)-sigma(1))*cosb2) &
           & /(cosb2-sinb2) - 0.5_dp * mZ2
   If (abs_mu2.Lt.0._dp) Then
    Write (ErrCan,*) 'Warning, in subroutine FirstGuess abs(mu)^2'
    Write (ErrCan,*) 'is smaller 0 :',abs_mu2
    Write (ErrCan,*) 'Setting it to 10^4.'
    Write(ErrCan,*) "Y_t, Y_b, Y_tau, tanb"
    Write(ErrCan,*) y_u(3,3), Y_d(3,3), y_l(3,3), vevS(2)/vevS(1),tanb
    Write(ErrCan,*) "m^2_H, sigma_i"
    Write(ErrCan,*) M_H2, sigma
    abs_mu2 = 1.e4_dp
   End If

   abs_mu = Sqrt(abs_mu2)
   mu = abs_mu * phase_mu
   mP02(2) = M_H2(2) - sigma(2) + M_H2(1) - sigma(1) + 2._dp * abs_mu2
   If (mP02(2).Lt.0._dp) Then
    Write (ErrCan,*) 'Warning, in subroutine FirstGuess'
    Write (ErrCan,*) 'mP02(2) is smaller 0 :',mP02(2)
    Write (ErrCan,*) 'Setting it to its modulus'
    mP02(2) = Abs(mP02(2))
   End If
   mP0(2) = Sqrt(mP02(2))
   Bimu = mP02(2) * tanb / (1 + tanb*tanb)

   gU1 =  Sqrt(3._dp / 5._dp ) * gauge(1)    
   gSU2 = gauge(2)    

  Iname = Iname - 1

 contains
  real(dp) function my_a0(m2)
  implicit none
   Real(dp), intent(in) :: m2
   if (m2.le.0._dp) then
    my_a0 = 0._dp
   else
    my_a0 = m2 * (1._dp - Log(m2/mudim)) 
   end if
  end  function my_a0
 end Subroutine FirstGuess

 Integer Function GetYukawaScheme()
 !-----------------------------------------------------------------------
 ! Sets the parameter YukawaScheme, which controls wheter the top (=1) or the
 ! down (=2) Yukawa couplings stay diagonal at the low scale 
 ! written by Werner Porod, 20.11.01
 !-----------------------------------------------------------------------
 Implicit None

  GetYukawaScheme = YukawaScheme

 End Function GetYukawaScheme

 Subroutine RunRGE(kont, delta, vevSM, g1, g2, mGUT)
 !-----------------------------------------------------------------------
 ! Uses Runge-Kutta method to integrate RGE's from M_Z to M_GUT
 ! and back, putting in correct thresholds. For the first iteration
 ! only the first 6 couplings are included and a common threshold is used.
 ! Written by Werner Porod, 10.07.99
 ! 07.03.2001: including right handed neutrinos
 ! 24.09.01: portation to f90
 ! 27.03.02: including a check if perturbation theory is valid
 ! 16.09.02: the electroweak scale is now set entirely outside, either 
 !           in the main program or in the routine sugra(...)
 !-----------------------------------------------------------------------
 Implicit None

  Integer, Intent(inout) :: kont
  Real(dp), Intent(in) :: delta, vevSM(2)
  Real(dp), Intent(inout) :: g1(57)
  Real(dp), Intent(out) :: g2(213), mGUT
  
  Integer:: i1, i2, SumI
  Real(dp) :: g1a(93), g2a(285), g5_a(59), g5_b(180), g1b(75), g2b(267) &
      & , g1c(79), g2c(277), g1d(118), g2d(356)
  Real(dp) :: tz, dt, t_out
  Real(dp) :: mudim, gGUT, g1_h(57), m_hi, m_lo, M15(3)
  Logical :: FoundUnification


  Real(dp), Parameter :: Umns(3,3) = Reshape(   Source = (/  &
      &    Sqrt2/Sqrt3, -ooSqrt2*ooSqrt3, -ooSqrt2*ooSqrt3   &
      &  , ooSqrt3,      ooSqrt3,          ooSqrt3           &
      &  , 0._dp ,       ooSqrt2,         -ooSqrt2 /), shape = (/3, 3/) )
  Real(dp), Parameter :: ZeroR2(2) = 0._dp
  Complex(dp), Dimension(3,3) :: mat3, UnuR, Ynu, Anu, Mr2

  Iname = Iname + 1
  NameOfUnit(Iname) = 'runRGE'

  !-------------------------------------
  ! running to the high scale
  !-------------------------------------
  g1_h = g1
  If ((HighScaleModel(1:9).Eq.'SUGRA_NuR').Or.(HighScaleModel.Eq.'SUGRA_SU5')) &
  Then
   m_lo = MnuR(1)
   FoundUnification = .False.
  Else If (HighScaleModel.Eq.'SEESAW_II') Then
   m_lo = M_H3(1)
   FoundUnification = .False.
  Else If (HighScaleModel.Eq.'GMSB') Then
   m_lo = MlambdaS
   FoundUnification = .True.
  Else If (UseFixedGUTScale) Then ! GUT scale is fixed
   m_lo = GUT_scale
   FoundUnification = .True.
  Else ! Sugra, strings with minimal particle content
   m_lo = 5.e14_dp
   FoundUnification = .False.
  End If

  tz = Log(mZ/m_lo)
  dt = - tz / 50._dp

  Call odeint(g1, 57, tz, 0._dp, delta, dt, 0._dp, rge57, kont)
  If (kont.Ne.0) Then
   Iname = Iname - 1
   Return
  End If
  !--------------------------
  ! check for perturbativity
  !--------------------------
  If ( (oo4pi*Maxval(g1**2)).Gt.1._dp) Then
   Write(ErrCan,*) "Non perturbative regime at high scale"
   If (ErrorLevel.Ge.2) Call TerminateProgram
!   Do i1=1,57
!    If (Abs(g1(i1)).Gt.1.e-12) Write(errcan,*)  i1,g1(i1),oo4pi*g1(i1)**2
!   end do
   Write(errcan,*) " "
   kont = -403
   Call AddError(403)
   Iname = Iname - 1
   Return
  End If
    
  !---------------------------
  ! looking for the GUT scale
  !---------------------------
  If (   (HighScaleModel.Eq.'SUGRA').Or.(HighScaleModel.Eq.'Oscar')         &
   & .Or.(HighScaleModel.Eq.'Str_A').Or.(HighScaleModel.Eq.'Str_B')         &
   & .Or.(HighScaleModel.Eq.'Str_C').Or.(HighScaleModel.Eq.'AMSB')  ) Then 

   If (.Not.UseFixedGUTScale) Then
    tz = Log(m_lo/1.e18_dp)
    dt = - tz / 50._dp

    Call odeintB(g1, 57, tz, 0._dp, delta, dt, 0._dp, rge57, t_out, kont)
    If (kont.Eq.0) Then
     FoundUnification = .True.
     mGUT = 1.e18_dp * Exp(t_out)
     gGUT = Sqrt( 0.5_dp * (g1(1)**2+g1(2)**2) )
     g1(1) = gGUT
     g1(2) = gGUT
     If (StrictUnification) g1(3) = gGUT
    Else
     Write(ErrCan,*) "kont",kont,delta,tz,dt
     Write(ErrCan,*) "m_t",mf_u(3)
     Write (ErrCan,*) "t_out",t_out,1.e18_dp * Exp(t_out)
     Do i1=1,57
      If ((g1(i1).Ne.0._dp).Or.(g1_h(i1).Ne.0._dp)) &
                 & Write(ErrCan,*) i1,g1_h(i1),g1(i1)
     End Do
     Write(ErrCan,*) " " 
     Iname = Iname - 1
     Return
    End If
   End If ! .not.UseFixedGUTScale

  Else If ((HighScaleModel.Eq.'SUGRA_NuR').Or.(HighScaleModel.Eq.'SUGRA_SU5')) &
   &  Then

   Call GToCouplings(g1,gauge_mR,Y_l_mR(1,:,:),Y_d_mR(1,:,:),Y_u_mR(1,:,:))

   Call CouplingsToG3(gauge_mR, Y_l_mR(1,:,:), Y_nu_mR(1,:,:), Y_d_mR(1,:,:) &
          & , Y_u_mR(1,:,:), MnuL5, g1a)
   !---------------------------
   ! running from m_R1 -> m_R2
   !---------------------------
   m_lo = MnuR(1)
   If (MnuR(1).Ne.MnuR(2)) Then
    m_hi = MnuR(2)
    tz = Log(m_lo / m_hi)
    dt = - tz / 50._dp  
    Call odeint(g1a, 93, tz, 0._dp, delta, dt, 0._dp, rge93, kont)

    Call GToCouplings3(g1a, gauge_mR, Y_l_mR(1,:,:), Y_nu_mR(1,:,:) &
           & , Y_d_mR(1,:,:), Y_u_mR(1,:,:), MnuL5 )

    Call CouplingsToG3(gauge_mR, Y_l_mR(1,:,:), Y_nu_mR(2,:,:), Y_d_mR(1,:,:) &
           & , Y_u_mR(1,:,:), MnuL5, g1a)
    m_lo = m_hi
   End If
   !---------------------------
   ! running from m_R2 -> m_R3
   !---------------------------
   If (m_lo.Ne.MnuR(3)) Then
    m_hi = MnuR(3)
    tz = Log(m_lo / m_hi)
    dt = - tz / 50._dp  

    Call odeint(g1a, 93, tz, 0._dp, delta, dt, 0._dp, rge93, kont)

    Call GToCouplings3(g1a, gauge_mR, Y_l_mR(1,:,:), Y_nu_mR(2,:,:) &
           & , Y_d_mR(1,:,:), Y_u_mR(1,:,:), MnuL5 )

    Call CouplingsToG3(gauge_mR, Y_l_mR(1,:,:), Y_nu_mR(3,:,:), Y_d_mR(1,:,:) &
          & , Y_u_mR(1,:,:), MnuL5, g1a)
    m_lo = m_hi
   End If

   !---------------------------
   ! running from m_R3 -> m_GUT
   !---------------------------

   If (UseFixedGUTScale) Then
    tz = Log(MnuR(3)/GUT_scale)
    mGUT = GUT_scale
    dt = - tz / 50._dp
    Call odeint(g1a, 93, tz, 0._dp, delta, dt, 0._dp, rge93, kont)
    If (kont.Ne.0) Then
     Iname = Iname -1
     Return
    End If

   Else
    If (g1a(1).Lt.g1a(2)) Then ! I am still below GUT scale
     tz = Log(MnuR(3)/1.e18_dp)
     dt = - tz / 50._dp
     Call odeintB(g1a, 93, tz, 0._dp, delta, dt, 0._dp, rge93, t_out, kont) 
     If (kont.Eq.0) Then
      FoundUnification = .True.
      mGUT = 1.e18_dp * Exp(t_out)
      gGUT = Sqrt( 0.5_dp * (g1a(1)**2+g1a(2)**2) )
      g1a(1) = gGUT
      g1a(2) = gGUT
      If (StrictUnification) g1a(3) = gGUT
     Else
      Iname = Iname - 1
      Return
     End If

    Else If (g1a(1).Eq.g1a(2)) Then ! I am at the GUT scale, very unlikely
                                    ! but possible
     FoundUnification = .True.
     mGUT = 1.e15_dp * Exp(t_out)
     gGUT = g1a(1)
     If (StrictUnification) g1a(3) = gGUT

    Else ! I have already crossed the GUT scale
     tz = Log(MnuR(3)/1.e15_dp)
     dt = - tz / 50._dp
     Call odeintC(g1a, 93, tz, 0._dp, delta, dt, 0._dp, rge93, t_out, kont)
     If (kont.Eq.0) Then
      FoundUnification = .True.
      mGUT = 1.e15_dp * Exp(t_out)
      gGUT = Sqrt( 0.5_dp * (g1a(1)**2+g1a(2)**2) )
      g1a(1) = gGUT
      g1a(2) = gGUT
      If (StrictUnification) g1a(3) = gGUT
     Else
      Iname = Iname - 1
      Return
     End If
    End If

   End If


   !----------------------------------------------------
   ! run up to SO(10) scale in case of the SU(5) model
   !----------------------------------------------------
   If (HighScaleModel.Eq.'SUGRA_SU5') Then
    tz = Log(mGUT/M_SO_10)
    dt = - tz / 50._dp

    g5_a = 0._dp
    g5_a(1) = g1a(1)
    g5_a(2:19) = g1a(58:75)    ! u-quark Yukawa couplines

    If (g1a(56).Gt.g1a(20)) Then
     g5_a(20:37) = g1a(40:57)   ! d-quark Yukawa couplines
    Else
     g5_a(20:37) = g1a(4:21)   ! lepton Yukawa couplines
    End If
    g5_a(38:55) = g1a(22:39)   ! neutrino Yukawa couplines
!    Write(*,*) "SU(5) Y_tau , Y_b, %",g1a(20),g1a(56),(g1a(20)-g1a(56))/g1a(20)
    g5_a(56) = Real(lam_0, dp)
    g5_a(57) = Aimag(lam_0)
    g5_a(58) = Real(lamp_0, dp)
    g5_a(59) = Aimag(lamp_0)

    Call odeint(g5_a, 59, tz, 0._dp, delta, dt, 0._dp, rge_SU5, kont)
   End If

  Else If (HighScaleModel.Eq.'SUGRA_NuR1') Then

    Call GToCouplings(g1,gauge_mR,Y_l_mR(1,:,:),Y_d_mR(1,:,:),Y_u_mR(1,:,:))
    Y_nu_mR = 0._dp
    Do i1=1,3
     Y_nu_mR(1,i1,i1)=Sqrt(2._dp * mf_nu(i1)*MnuR(i1)) / vevSM(2)
    End Do

    Call CouplingsToG2(gauge_mR, Y_l_mR(1,:,:), Y_nu_mR(1,:,:), Y_d_mR(1,:,:) &
             & , Y_u_mR(1,:,:), g1a)

    tz = Log(mGUT/GUT_scale)
    dt = tz / 50._dp  

   If (UseFixedGUTScale) Then
    tz = Log(mGUT/GUT_scale)
    mGUT = GUT_scale
    dt = - tz / 50._dp
    Call odeint(g1a, 75, tz, 0._dp, delta, dt, 0._dp, rge75, kont)
    If (kont.Ne.0) Then
     Iname = Iname -1
     Return
    End If

   Else
    tz = Log(mGUT/1.e18_dp)
    dt = - tz / 50._dp
    Call odeintB(g1a, 75, tz, 0._dp, delta, dt, 0._dp, rge75, t_out, kont)
    If (kont.Eq.0) Then
     FoundUnification = .True.
     mGUT = 1.e18_dp * Exp(t_out)
     gGUT = Sqrt( 0.5_dp * (g1a(1)**2+g1a(2)**2) )
     g1a(1) = gGUT
     g1a(2) = gGUT
     If (StrictUnification) g1a(3) = gGUT
    Else
     Iname = Iname - 1
     Return
    End If
   End If

  Else If ((HighScaleModel.Eq.'SEESAW_II').and.Fifteen_plet) Then

    Call GToCouplings(g1, gauge_mH3, Y_l_mH3, Y_d_mH3, Y_u_mH3)

    M15 = M_H3(1)
    Call CouplingsToG5(gauge_mH3, Y_l_mH3, Y_T_mH3, Y_d_mH3, Y_u_mH3 &
            & , Y_Z_mH3, Y_S_mH3, lam12_MH3(1), lam12_MH3(2), M15, g1d)

    Delta_b_1 = 7._dp
    Delta_b_2(1,1) = 181._dp/15._dp
    Delta_b_2(1,2) = 29.4_dp 
    Delta_b_2(1,3) = 656._dp/15._dp
    Delta_b_2(2,1) = 9.8_dp
    Delta_b_2(2,2) = 69._dp
    Delta_b_2(2,3) = 16._dp
    Delta_b_2(3,1) = 82._dp/15._dp
    Delta_b_2(3,2) = 6._dp
    Delta_b_2(3,3) = 358._dp/3._dp

   !-----------------------------------------------------
   ! adding shifts to gauge couplings
   !-----------------------------------------------------
   gauge_mH3(1) = gauge_mH3(1) * (1._dp - oo16pi2 * gauge_mH3(1)**2           &
                &                       * (8._dp/3._dp*Log(MS15_mH3/MT15_mH3) &
                &                         + Log(MZ15_mH3/MT15_mH3) /6._dp ) )
   gauge_mH3(2) = gauge_mH3(2) * (1._dp - oo16pi2 * gauge_mH3(2)**2           &
                &                       * 1.5_dp *Log(MZ15_mH3/MT15_mH3) )
   gauge_mH3(3) = gauge_mH3(3) * (1._dp - oo16pi2 * gauge_mH3(3)**2           &
                &                       * (2.5_dp*Log(MS15_mH3/MT15_mH3) &
                &                         + Log(MZ15_mH3/MT15_mH3) ) )

   If (UseFixedGUTScale) Then
    tz = Log(m_lo/GUT_scale)
    mGUT = GUT_scale
    dt = - tz / 50._dp
    Call odeint(g1d, 118, tz, 0._dp, delta, dt, 0._dp, rge118, kont)
    If (kont.Ne.0) Then
     Iname = Iname -1
     Return
    End If

   Else

    If (g1d(1).Lt.g1d(2)) Then ! I am still below GUT scale
     tz = Log(m_lo/1.e18_dp)
     dt = - tz / 50._dp
     Call odeintB(g1d, 118, tz, 0._dp, delta, dt, 0._dp, rge118, t_out, kont) 

     If (kont.Eq.0) Then
      FoundUnification = .True.
      mGUT = 1.e18_dp * Exp(t_out)
      gGUT = Sqrt( 0.5_dp * (g1d(1)**2+g1d(2)**2) )
      g1d(1) = gGUT
      g1d(2) = gGUT
      If (StrictUnification) g1d(3) = gGUT
     Else
      Iname = Iname - 1
      Return
     End If

    Else If (g1d(1).Eq.g1d(2)) Then ! I am at the GUT scale, very unlikely
                                    ! but possible
     FoundUnification = .True.
     mGUT = 1.e15_dp * Exp(t_out)
     gGUT = g1d(1)
     If (StrictUnification) g1d(3) = gGUT

    Else ! I have already crossed the GUT scale
     tz = Log(m_lo/1.e15_dp)
     dt = - tz / 50._dp
     Call odeintC(g1d, 118, tz, 0._dp, delta, dt, 0._dp, rge118, t_out, kont)
     If (kont.Eq.0) Then
      FoundUnification = .True.
      mGUT = 1.e15_dp * Exp(t_out)
      gGUT = Sqrt( 0.5_dp * (g1d(1)**2+g1d(2)**2) )
      g1d(1) = gGUT
      g1d(2) = gGUT
      If (StrictUnification) g1d(3) = gGUT
     Else
      Iname = Iname - 1
      Return
     End If
    End If

   End If

  Else If (HighScaleModel.Eq.'SEESAW_II') Then

    Call GToCouplings(g1, gauge_mH3, Y_l_mH3, Y_d_mH3, Y_u_mH3)

    Call CouplingsToG4(gauge_mH3, Y_l_mH3, Y_T_mH3, Y_d_mH3, Y_u_mH3 &
            & , lam12_MH3(1), lam12_MH3(2), g1c)

    Delta_b_1(1) = 3.6_dp
    Delta_b_1(2) = 4._dp

    Delta_b_2(1,1) = 8.64_dp
    Delta_b_2(1,2) = 28.8_dp 
    Delta_b_2(2,1) = 9.6_dp
    Delta_b_2(2,2) = 48._dp

   If (UseFixedGUTScale) Then
    tz = Log(m_lo/GUT_scale)
    mGUT = GUT_scale
    dt = - tz / 50._dp
    Call odeint(g1c, 79, tz, 0._dp, delta, dt, 0._dp, rge79, kont)
    If (kont.Ne.0) Then
     Iname = Iname -1
     Return
    End If

   Else

    If (g1c(1).Lt.g1c(2)) Then ! I am still below GUT scale
     tz = Log(m_lo/1.e18_dp)
     dt = - tz / 50._dp
     Call odeintB(g1c, 79, tz, 0._dp, delta, dt, 0._dp, rge79, t_out, kont) 

     If (kont.Eq.0) Then
      FoundUnification = .True.
      mGUT = 1.e18_dp * Exp(t_out)
      gGUT = Sqrt( 0.5_dp * (g1c(1)**2+g1c(2)**2) )
      g1c(1) = gGUT
      g1c(2) = gGUT
      If (StrictUnification) g1c(3) = gGUT
     Else
      Iname = Iname - 1
      Return
     End If

    Else If (g1c(1).Eq.g1c(2)) Then ! I am at the GUT scale, very unlikely
                                    ! but possible
     FoundUnification = .True.
     mGUT = 1.e15_dp * Exp(t_out)
     gGUT = g1c(1)
     If (StrictUnification) g1c(3) = gGUT

    Else ! I have already crossed the GUT scale
     tz = Log(m_lo/1.e15_dp)
     dt = - tz / 50._dp
     Call odeintC(g1c, 79, tz, 0._dp, delta, dt, 0._dp, rge79, t_out, kont)
     If (kont.Eq.0) Then
      FoundUnification = .True.
      mGUT = 1.e15_dp * Exp(t_out)
      gGUT = Sqrt( 0.5_dp * (g1c(1)**2+g1c(2)**2) )
      g1c(1) = gGUT
      g1c(2) = gGUT
      If (StrictUnification) g1c(3) = gGUT
     Else
      Iname = Iname - 1
      Return
     End If
    End If

   End If

  End If

  If (.Not.FoundUnification) Then
   Write (ErrCan,*) 'SUGRA: no unification found'
   SugraErrors(1) = .True.
   kont = -404
   Call AddError(404)
   Iname = Iname - 1
   Return
  End If

  !------------------------------------
  ! Saving parameters at high scale
  !------------------------------------
  If (HighScaleModel.Eq."GMSB") Then
   mGUT_Save = MlambdaS
  Else
   mGUT_Save = mGUT
  End If
  !---------------------------------------
  ! boundary condition at the high scale
  !---------------------------------------
  If (HighScaleModel.Eq.'SUGRA_NuR') Then
   g1a(22:39) = g1a(58:75) ! setting Y_nu = Y_u
   Call BoundaryHS(g1a,g2a)
  Else If (HighScaleModel.Eq.'SUGRA_NuR1') Then
   Call BoundaryHS(g1b,g2b)

  Else If ((HighScaleModel.Eq.'SEESAW_II').and.Fifteen_plet) Then
   Call BoundaryHS(g1d,g2d)

  Else If (HighScaleModel.Eq.'SEESAW_II') Then
   Call BoundaryHS(g1c,g2c)

  Else If (HighScaleModel.Eq.'SUGRA_SU5') Then
   g5_b = 0._dp
   g5_b(1:59) = g5_a   ! gauge and Yukawa coupling
   g5_b(38:55) = g5_b(2:19) ! setting Y_nu = Y_u
   g5_b(60:63) = 0._dp ! bilinear parameters
   g5_b(64) = Real( Mi_0(1), dp )
   g5_b(65) = Aimag( Mi_0(1) )
   g5_b(66:123) = AoY_u_0(1,1) * g5_a(2:59)
   Do i1=1,3
    g5_b(8*i1+116) = M2_H_0(1) + D_SO_10          ! 10-plets
    g5_b(8*i1+134) = M2_H_0(1) - 3._dp * D_SO_10  ! 5-plets, matter
    g5_b(8*i1+152) = M2_H_0(1) + 5._dp * D_SO_10  ! singlet, nu_R
   End Do
   g5_b(178) = M2_H_0(1) - 2._dp * D_SO_10  ! 5-plets, u-type Higgs
   g5_b(179) = M2_H_0(1) + 2._dp * D_SO_10  ! 5-plets, d-type Higgs
   g5_b(180) = M2_H_0(1)                    ! Higgs 24-plet
!Write(*,*) "SO(10) Y_b Y_t",g5_b(36),g5_b(18),(g5_b(36)-g5_b(18))/g5_b(36)
!Write(*,*) "lam, lam'",Real(g5_b(56:58:2))
  Else
   Call BoundaryHS(g1,g2)
  End If
  
  !--------------------------------------
  ! running down to the electroweak scale
  !--------------------------------------
  If ((HighScaleModel.Eq.'SUGRA_NuR').Or.(HighScaleModel.Eq.'SUGRA_SU5')) Then
   !-------------------------------------
   ! m_SO(10) -> m_GUT in case of SU(5)
   !-------------------------------------
   If (HighScaleModel.Eq.'SUGRA_SU5') Then
    tz = Log(mGUT/M_SO_10)
    dt = tz / 50._dp
    Call odeint(g5_b, 180, 0._dp, tz, delta, dt, 0._dp, rge_SU5, kont)

    g2a(1:75) = g1a(1:75)  ! using orginal boundary conditions
    g2a(22:39) = g5_b(38:55) ! neutrino Yukawa couplings
    g2a(76:77) = g5_b(64:65)  ! gaugino mass parameters
    g2a(78:79) = g5_b(64:65)
    g2a(80:81) = g5_b(64:65)
    g2a(82:99) = g5_b(84:101)    ! A_l = A_d
    g2a(100:117) = g5_b(102:119) ! A_nu
    g2a(118:135) = g5_b(84:101)  ! A_d = A_l
    g2a(136:153) = g5_b(66:83)   ! A_u
    g2a(154:171) = g5_b(124:141) ! M_E = M_Q = M_U
    g2a(172:189) = g5_b(142:159) ! M_L = M_D
    g2a(190:207) = g5_b(160:177) ! M_R
    g2a(208:225) = g5_b(142:159) ! M_L = M_D
    g2a(226:243) = g5_b(124:141) ! M_Q = M_U = M_E
    g2a(244:261) = g5_b(124:141) ! M_U = M_E = M_Q
    g2a(262:263) = g5_b(178:179) ! M_H
    g2a(264:285) = 0._dp         ! mu, B, MnuL5
    M2S_GUT = g5_b(180)
    Alam_GUT = Cmplx(g5_b(120),g5_b(121),dp)
    Alamp_GUT = Cmplx(g5_b(122),g5_b(123),dp)
    Do i1=1,3
     Do i2=1,3
      SumI = 6*i1+2*i2
      Ynu(i1,i2) = Cmplx( g2a(SumI+14), g2a(SumI+15),dp )
      Anu(i1,i2) = Cmplx( g2a(SumI+92), g2a(SumI+93),dp )
      Mr2(i1,i2) = Cmplx( g2a(SumI+182), g2a(SumI+183),dp )
     End Do
    End Do

   Else

    Ynu = Y_nu_0
    Anu = A_nu_0
!Write(*,*) "Anu",Anu
    Mr2 = M2_R_0
!Write(*,*) "Mr2",Mr2
   End If

    !--------------------------------------
    ! recalculating m_Nu_R, if necessary
    !--------------------------------------
    If (.Not.Fixed_Nu_Yukawas) Then
     mat3 = 0._dp
     mat3(1,1) = 1._dp / mf_nu(1)
     mat3(2,2) = 1._dp / mf_nu(2)
     mat3(3,3) = 1._dp / mf_nu(3)

     mat3 = Matmul(Umns,Matmul(mat3,Transpose(Umns)))
     mat3 = vevSM(2)**2 * Matmul(Ynu,Matmul(mat3,Transpose(Ynu)))

     Call Neutrinomasses(mat3, mNuR, UnuR, kont)

    Else ! for the rotation below
     UnuR = id3C
    End If
!Write(*,*) "mNuR",Real(mNuR)
!Write(*,*) "mNuL",real(mf_nu) 
!Write(*,*) "UNuR",Cmplx(UNuR(1,:))
!Write(*,*) "    ",Cmplx(UNuR(2,:))
!Write(*,*) "    ",Cmplx(UNuR(3,:))
!Write(*,*) " "
    !--------------------------------------------
    ! rotating R-neutrinos to mass eigenbasis
    !--------------------------------------------
    Ynu = Matmul(UnuR,Ynu)
    Anu = Matmul(UnuR,Anu)
    MR2 = Matmul(Transpose(Conjg(UnuR)),Matmul(MR2,UnuR))

    Do i1=1,3
     Do i2=1,3
      SumI = 6*i1+2*i2
      g2a(SumI+14) = Real(Ynu(i1,i2),dp)
      g2a(SumI+15) = Aimag(Ynu(i1,i2))
      g2a(SumI+92) = Real(Anu(i1,i2),dp)
      g2a(SumI+93) = Aimag(Anu(i1,i2))
      g2a(SumI+182) = Real(MR2(i1,i2),dp)
      g2a(SumI+183) = Aimag(MR2(i1,i2))
     End Do
    End Do

    
   !------------------------
   ! m_GUT -> m_nuR_3
   !------------------------
   m_hi = mGUT
   m_lo = MNuR(3)
   If (Abs(m_lo).Lt.Abs(m_hi)) Then
    tz = Log(Abs(m_hi/m_lo))
    dt = - tz / 50._dp
    Call odeint(g2a, 285, tz, 0._dp, delta, dt, 0._dp, rge285, kont)
    m_hi = m_lo
   Endif

   Call GToParameters3(g2a, gauge_mR, y_l_mR(3,:,:), y_nu_mR(3,:,:)          &
      & , y_d_mR(3,:,:), y_u_mR(3,:,:), Mi_mR, A_l_mR(3,:,:), A_nu_mR(3,:,:) &
      & , A_d_mR(3,:,:), A_u_mR(3,:,:), M2_E_mR(3,:,:), M2_L_mR(3,:,:)       &
      & , M2_R_mR(3,:,:), M2_D_mR(3,:,:), M2_Q_mR(3,:,:), M2_U_mR(3,:,:)     &
      & , M2_H_mR, mu_mR, B_mR, MnuL5)

   Do i1=1,3
    Do i2=1,3
     MnuL5(i1,i2) = - Y_nu_mR(3,3,i1) * Y_nu_mR(3,3,i2) / MNuR(3)
    End Do
   End Do
   Y_nu_mR(2,:,:) = Y_nu_mR(3,:,:)
   Y_nu_mR(2,3,:) = 0._dp
   A_nu_mR(2,:,:) = A_nu_mR(3,:,:)
   A_nu_mR(2,3,:) = 0._dp
   M2_R_mR(2,:,:) = M2_R_mR(3,:,:)
   M2_R_mR(2,3,:) = 0._dp
   M2_R_mR(2,:,3) = 0._dp
   !------------------------
   ! m_nuR_3 -> m_nuR_2
   !------------------------
   Call ParametersToG3(gauge_mR, y_l_mR(3,:,:), y_nu_mR(2,:,:), y_d_mR(3,:,:) &
      & , y_u_mR(3,:,:), Mi_mR, A_l_mR(3,:,:), A_nu_mR(2,:,:), A_d_mR(3,:,:)  &
      & , A_u_mR(3,:,:), M2_E_mR(3,:,:), M2_L_mR(3,:,:), M2_R_mR(2,:,:)       &
      & , M2_D_mR(3,:,:), M2_Q_mR(3,:,:), M2_U_mR(3,:,:), M2_H_mR, mu_mR      &
      & , B_mR, MnuL5, g2a)

   m_lo = MNuR(2)
   If (Abs(m_lo).Lt.Abs(m_hi)) Then
    tz = Log(Abs(m_hi/m_lo))
    dt = - tz / 50._dp
    Call odeint(g2a, 285, tz, 0._dp, delta, dt, 0._dp, rge285, kont)
    m_hi = m_lo
   Endif

   Call GToParameters3(g2a, gauge_mR, y_l_mR(2,:,:), y_nu_mR(2,:,:)          &
      & , y_d_mR(2,:,:), y_u_mR(2,:,:), Mi_mR, A_l_mR(2,:,:), A_nu_mR(2,:,:) &
      & , A_d_mR(2,:,:), A_u_mR(2,:,:), M2_E_mR(2,:,:), M2_L_mR(2,:,:)       &
      & , M2_R_mR(2,:,:), M2_D_mR(2,:,:), M2_Q_mR(2,:,:), M2_U_mR(2,:,:)     &
      & , M2_H_mR, mu_mR, B_mR, MnuL5)

   Do i1=1,3
    Do i2=1,3
     MnuL5(i1,i2) = MnuL5(i1,i2) - Y_nu_mR(2,2,i1) * Y_nu_mR(2,2,i2) / MNuR(2)
    End Do
   End Do
   Y_nu_mR(1,:,:) = Y_nu_mR(2,:,:)
   Y_nu_mR(1,2,:) = 0._dp
   A_nu_mR(1,:,:) = A_nu_mR(2,:,:)
   A_nu_mR(1,2,:) = 0._dp
   M2_R_mR(1,:,:) = M2_R_mR(2,:,:)
   M2_R_mR(1,2,:) = 0._dp
   M2_R_mR(1,:,2) = 0._dp
   !------------------------
   ! m_nuR_2 -> m_nuR_1
   !------------------------
   Call ParametersToG3(gauge_mR, y_l_mR(2,:,:), y_nu_mR(1,:,:), y_d_mR(2,:,:) &
      & , y_u_mR(2,:,:), Mi_mR, A_l_mR(2,:,:), A_nu_mR(1,:,:), A_d_mR(2,:,:)  &
      & , A_u_mR(2,:,:), M2_E_mR(2,:,:), M2_L_mR(2,:,:), M2_R_mR(1,:,:)       &
      & , M2_D_mR(2,:,:), M2_Q_mR(2,:,:), M2_U_mR(2,:,:), M2_H_mR, mu_mR      &
      & , B_mR, MnuL5, g2a)

   m_lo = MNuR(1)
   If (Abs(m_lo).Lt.Abs(m_hi)) Then
    tz = Log(Abs(m_hi/m_lo))
    dt = - tz / 50._dp
    Call odeint(g2a, 285, tz, 0._dp, delta, dt, 0._dp, rge285, kont)
    m_hi = m_lo
   Endif

   Call GToParameters3(g2a, gauge_mR, y_l_mR(1,:,:), y_nu_mR(1,:,:)          &
      & , y_d_mR(1,:,:), y_u_mR(1,:,:), Mi_mR, A_l_mR(1,:,:), A_nu_mR(1,:,:) &
      & , A_d_mR(1,:,:), A_u_mR(1,:,:), M2_E_mR(1,:,:), M2_L_mR(1,:,:)       &
      & , M2_R_mR(1,:,:), M2_D_mR(1,:,:), M2_Q_mR(1,:,:), M2_U_mR(1,:,:)     &
      & , M2_H_mR, mu_mR, B_mR, MnuL5)

   Do i1=1,3
    Do i2=1,3
     MnuL5(i1,i2) = MnuL5(i1,i2) - Y_nu_mR(1,1,i1) * Y_nu_mR(1,1,i2) / MNuR(1)
    End Do
   End Do
   !------------------------
   ! m_nuR_1 -> Q_EWSB
   !------------------------
   Call ParametersToG3(gauge_mR, y_l_mR(1,:,:), Zero33C, y_d_mR(1,:,:)     &
        & , y_u_mR(1,:,:), Mi_mR, A_l_mR(1,:,:), Zero33C, A_d_mR(1,:,:)    &
        & , A_u_mR(1,:,:), M2_E_mR(1,:,:), M2_L_mR(1,:,:), Zero33C         &
        & , M2_D_mR(1,:,:), M2_Q_mR(1,:,:), M2_U_mR(1,:,:), M2_H_mR, mu_mR &
        & , B_mR, MnuL5, g2a)

   mudim = GetRenormalizationScale()
   mudim = Max(mudim, mZ2)
   tz = 0.5_dp * Log(m_hi**2/mudim)
   dt = - tz / 100._dp

   Call odeint(g2a, 285, tz, 0._dp, delta, dt, 0._dp, rge285, kont)

   Call GToParameters3(g2a, gauge, y_l, Y_nu, y_d, y_u, Mi, A_l, A_nu, A_d &
      & , A_u, M2_E, M2_L, M2_R, M2_D, M2_Q, M2_U, M2_H, mu, B, MnuL5)

   Call ParametersToG(gauge, y_l, y_d, y_u, Mi, A_l, A_d, A_u, M2_E, M2_L  &
      & , M2_D, M2_Q, M2_U, M2_H, mu, B, g2)

  Else If (HighScaleModel.Eq.'SUGRA_NuR1') Then
   mudim = MNuR(1)**2
   tz = 0.5_dp * Log(mudim/mGUT**2)
   dt = tz / 50._dp
   Call odeint(g2a, 267, 0._dp, tz, delta, dt, 0._dp, rge267, kont)

   Call GToParameters2(g2a, gauge_mR, y_l_mR, y_nu_mR, y_d_mR, y_u_mR, Mi_mR &
          & , A_l_mR, A_nu_mR, A_d_mR, A_u_mR, M2_E_mR, M2_L_mR, M2_R_mR     &
          & , M2_D_mR, M2_Q_mR, M2_U_mR, M2_H_mR, mu_mR, B_mR)

   Call ParametersToG(gauge_mR, y_l_mR, y_d_mR, y_u_mR, Mi_mR, A_l_mR, A_d_mR &
             & , A_u_mR, M2_E_mR, M2_L_mR, M2_D_mR, M2_Q_mR, M2_U_mR, M2_H_mR &
             & , mu_mR, B_mR, g2)

   mudim = GetRenormalizationScale()
   mudim = Max(mudim, mZ2)

   tz = 0.5_dp * Log(mudim/mNuR(1)**2)
   dt = tz / 100._dp
   Call odeint(g2, 213, 0._dp, tz, delta, dt, 0._dp, rge213, kont)

  Else If ((HighScaleModel.Eq.'SEESAW_II').and.Fifteen_plet) Then

   If ( (oo4pi*Maxval(g2d(1:115)**2)).Gt.1._dp) Then
    Write(ErrCan,*) "Non perturbative regime at M_GUT"
    If (ErrorLevel.Ge.2) Call TerminateProgram
    Write(errcan,*) " "
    kont = -403
    Call AddError(403)
    Iname = Iname - 1
    Return
   End If
   
   !-------------------------
   ! run only if m_H < m_GUT
   !-------------------------
   If (m_H3(1).Lt.mGUT) Then
    mudim = M_H3(1)**2
    tz = 0.5_dp * Log(mudim/mGUT**2)
    dt = tz / 50._dp
    Call odeint(g2d, 356 , 0._dp, tz, delta, dt, 0._dp, rge356, kont)
    m_lo = M_H3(1)
   Else
     m_lo = mGUT
   End If

   If ( (oo4pi*Maxval(g2d(1:115)**2)).Gt.1._dp) Then
    Write(ErrCan,*) "Non perturbative regime at M_H3"
    If (ErrorLevel.Ge.2) Call TerminateProgram
    Write(errcan,*) " "
    kont = -403
    Call AddError(403)
    Iname = Iname - 1
    Return
   End If

   Call GToParameters5(g2d, gauge_mH3, y_l_mH3, y_T_mH3, y_d_mH3, y_u_mH3     &
          & , y_Z_mH3, y_S_mH3, lam12_mH3(1), lam12_mH3(2), Mi_mH3, A_l_mH3   &
          & , A_T_mH3, A_d_mH3, A_u_mH3, A_Z_mH3, A_S_mH3, Alam12_MH3(1)      &
          & , Alam12_MH3(2), M2_E_mH3, M2_L_mH3, M2_D_mH3, M2_Q_mH3, M2_U_mH3 &
          & , M2_H_mH3, M2_T_mH3, M2_Z_mH3, M2_S_mH3, MT15_mH3, MZ15_mH3      &
          & , MS15_mH3, mu_mH3, B_mH3, MnuL5)

   MnuL5 = - lam12_MH3(2) * y_T_mH3 / M_H3(1)

   Delta_b_1 = 0._dp ! decoupling the Higgs triplets
   Delta_b_2 = 0._dp ! decoupling the Higgs triplets
   !-----------------------------------------------------
   ! adding shifts to gauge couplings
   !-----------------------------------------------------
   gauge_mH3(1) = gauge_mH3(1) * (1._dp + oo16pi2 * gauge_mH3(1)**2           &
                &                       * (8._dp/3._dp*Log(MS15_mH3/MT15_mH3) &
                &                         + Log(MZ15_mH3/MT15_mH3) /6._dp ) )
   gauge_mH3(2) = gauge_mH3(2) * (1._dp + oo16pi2 * gauge_mH3(2)**2           &
                &                       * 1.5_dp *Log(MZ15_mH3/MT15_mH3) )
   gauge_mH3(3) = gauge_mH3(3) * (1._dp + oo16pi2 * gauge_mH3(3)**2           &
                &                       * (2.5_dp*Log(MS15_mH3/MT15_mH3) &
                &                         + Log(MZ15_mH3/MT15_mH3) ) )
!Write(*,*) "a",Real(mi_mh3)
   Mi_mH3(1) = Mi_mH3(1) * (1._dp + oo16pi2 * gauge_mH3(1)**2           &
                &                       * (8._dp/3._dp*Log(MS15_mH3/MT15_mH3) &
                &                         + Log(MZ15_mH3/MT15_mH3) /6._dp ) )
   Mi_mH3(2) = Mi_mH3(2) * (1._dp + oo16pi2 * gauge_mH3(2)**2           &
                &                       * 1.5_dp *Log(MZ15_mH3/MT15_mH3) )
   Mi_mH3(3) = Mi_mH3(3) * (1._dp + oo16pi2 * gauge_mH3(3)**2           &
                &                       * (2.5_dp*Log(MS15_mH3/MT15_mH3) &
                &                         + Log(MZ15_mH3/MT15_mH3) ) )
!Write(*,*) "b",Real(mi_mh3)

   Call ParametersToG4(gauge_mH3, y_l_mH3, Zero33C, y_d_mH3, y_u_mH3   &
          & , ZeroC, ZeroC, Mi_mH3, A_l_mH3, Zero33C, A_d_mH3 &
          & , A_u_mH3, ZeroC, ZeroC, M2_E_mH3, M2_L_mH3     &
          & , M2_D_mH3, M2_Q_mH3, M2_U_mH3, M2_H_mH3, ZeroR2, mu_mH3      &
          & , B_mH3, MnuL5, g2c)

   mudim = GetRenormalizationScale()
   mudim = Max(mudim, mZ2)

   tz = 0.5_dp * Log(mudim/m_lo**2)
   dt = tz / 100._dp
   Call odeint(g2c, 277, 0._dp, tz, delta, dt, 0._dp, rge277, kont)

   Call GToParameters4(g2c, gauge, y_l, y_T, y_d, y_u, lam12(1), lam12(2), Mi &
          & , A_l, A_T, A_d, A_u, Alam12(1), Alam12(2), M2_E, M2_L, M2_D      &
          & , M2_Q, M2_U, M2_H, M2_T, mu, B, MnuL5)

   Call ParametersToG(gauge, y_l, y_d, y_u, Mi, A_l, A_d, A_u, M2_E, M2_L  &
      & , M2_D, M2_Q, M2_U, M2_H, mu, B, g2)

  Else If (HighScaleModel.Eq.'SEESAW_II') Then

   If ( (oo4pi*Maxval(g2c(1:79)**2)).Gt.1._dp) Then
    Write(ErrCan,*) "Non perturbative regime at M_GUT"
    If (ErrorLevel.Ge.2) Call TerminateProgram
    Write(errcan,*) " "
    kont = -403
    Call AddError(403)
    Iname = Iname - 1
    Return
   End If
   
   !-------------------------
   ! run only if m_H < m_GUT
   !-------------------------
   If (m_H3(1).Lt.mGUT) Then
    mudim = M_H3(1)**2
    tz = 0.5_dp * Log(mudim/mGUT**2)
    dt = tz / 50._dp
    Call odeint(g2c, 277, 0._dp, tz, delta, dt, 0._dp, rge277, kont)
    m_lo = M_H3(1)
   Else
     m_lo = mGUT
   End If

   If ( (oo4pi*Maxval(g2c(1:79)**2)).Gt.1._dp) Then
    Write(ErrCan,*) "Non perturbative regime at M_H3"
    If (ErrorLevel.Ge.2) Call TerminateProgram
    Write(errcan,*) " "
    kont = -403
    Call AddError(403)
    Iname = Iname - 1
    Return
   End If

   Call GToParameters4(g2c, gauge_mH3, y_l_mH3, y_T_mH3, y_d_mH3, y_u_mH3   &
          & , lam12_mH3(1), lam12_mH3(2), Mi_mH3, A_l_mH3, A_T_mH3, A_d_mH3 &
          & , A_u_mH3, Alam12_MH3(1), Alam12_MH3(2), M2_E_mH3, M2_L_mH3     &
          & , M2_D_mH3, M2_Q_mH3, M2_U_mH3, M2_H_mH3, M2_T_mH3, mu_mH3      &
          & , B_mH3, MnuL5)

   MnuL5 = - lam12_MH3(2) * y_T_mH3 / M_H3(1)

   Delta_b_1 = 0._dp ! decoupling the Higgs triplets
   Delta_b_2 = 0._dp ! decoupling the Higgs triplets
   Call ParametersToG4(gauge_mH3, y_l_mH3, Zero33C, y_d_mH3, y_u_mH3   &
          & , ZeroC, ZeroC, Mi_mH3, A_l_mH3, Zero33C, A_d_mH3 &
          & , A_u_mH3, ZeroC, ZeroC, M2_E_mH3, M2_L_mH3     &
          & , M2_D_mH3, M2_Q_mH3, M2_U_mH3, M2_H_mH3, ZeroR2, mu_mH3      &
          & , B_mH3, MnuL5, g2c)

   mudim = GetRenormalizationScale()
   mudim = Max(mudim, mZ2)

   tz = 0.5_dp * Log(mudim/m_lo**2)
   dt = tz / 100._dp
   Call odeint(g2c, 277, 0._dp, tz, delta, dt, 0._dp, rge277, kont)

   Call GToParameters4(g2c, gauge, y_l, y_T, y_d, y_u, lam12(1), lam12(2), Mi &
          & , A_l, A_T, A_d, A_u, Alam12(1), Alam12(2), M2_E, M2_L, M2_D      &
          & , M2_Q, M2_U, M2_H, M2_T, mu, B, MnuL5)

   Call ParametersToG(gauge, y_l, y_d, y_u, Mi, A_l, A_d, A_u, M2_E, M2_L  &
      & , M2_D, M2_Q, M2_U, M2_H, mu, B, g2)

  Else

   mudim = GetRenormalizationScale()
   mudim = Max(mudim, mZ2)

   tz = 0.5_dp * Log(mudim/mGUT_save**2)
   dt = tz / 100._dp

   Call odeint(g2, 213, 0._dp, tz, delta, dt, 0._dp, rge213, kont)

  End If

  Iname = Iname - 1


  900 Format(a20,e15.6)
  910 Format(a15,3e15.6)
  920 Format(a7,e14.5,"+ i",e14.5,"  ",e14.5,"+ i", e14.5,"  " &
            &  ,e14.5,"+ i",e14.5)

 End Subroutine RunRGE

 Subroutine RunRGEup(g2, mGUT, Qvec, g_out, g_out2, kont)
 !-----------------------------------------------------------------------
 ! Uses Runge-Kutta method to integrate RGE's from M_Z to M_GUT
 ! Written by Werner Porod, 17.04.02
 ! 17.04.02 : - including the mSugra case and a simplified version
 !              for varying m_t
 !            - setting flag for writing
 ! 01.02.03: remodelling everything, because this routine should only
 !           serve as possiblity to run up RGEs, structure is build such
 !           that right handed neutrinos can be included
 !-----------------------------------------------------------------------
 Implicit None

  Integer, Intent(inout) :: kont
  Real(dp), Intent(in) :: g2(:), mGUT
  Real(dp), Intent(out) :: g_out(:,:), g_out2(:,:), Qvec(:)
  
  Logical :: check
  Integer:: i1, len1, len2, len3, len4
  Real(dp) :: g2a(213), w2(213,3), g2b(267), w2b(267,3), tz, dt, t, mudim

  Iname = Iname + 1
  NameOfUnit(Iname) = 'RunRGEup'

  !-------------------------------------------
  ! first a check if everthing is consistent
  !-------------------------------------------
  len1 = Size( g2 )
  len2 = Size( Qvec )
  len3 = Size( g_out, dim=1 )
  len4 = Size( g_out, dim=2 )

  check = .True.  
  If (len1.Ne.len4) check = .False. ! size of parameter vector do not conincide
  If (len2.Ne.len3) check = .False. ! number of steps do not conincide
  If (.Not.check) Then
   Write(ErrCan,*) "Problem in routine "//NameOfUnit(Iname)
   Write(ErrCan,*) "dimension of g2   :",len1
   Write(ErrCan,*) "dimension of Qvec :",len2
   Write(ErrCan,*) "dimension of g2   :",len1
   If (ErrorLevel.Ge.0) Call TerminateProgram
  End If   

  !---------------------------------------------
  ! data for running: mudim is low energy scale
  !---------------------------------------------
  mudim = GetRenormalizationScale()
  mudim = Sqrt(mudim)
  tz = Log(mudim/mGUT)
  dt = - tz / Real(len2-1, dp)
  g2a = g2
  !------------------
  ! now the running
  !------------------
  g_out(1,:) = g2a
  g_out2 = 0._dp
  If (HighScaleModel.Eq.'SUGRA_NuR') Then
   tz = Log(mudim/mNuR(3))
   dt = - tz / Real(len2-18, dp)
   Do i1=0,len2-19
    t =  tz + dt * i1
    Qvec(i1+1) = mNuR(3) * Exp(t)
    Call rkstp(dt,t,g2a,rge213,w2)
    g_out(2+i1,:) = g2a
   End Do
    Qvec(i1+1) = mNuR(3)
   Call GToParameters(g2a, gauge_mR, y_l_mR, y_d_mR, y_u_mR, Mi_mR &
          & , A_l_mR, A_d_mR, A_u_mR, M2_E_mR, M2_L_mR     &
          & , M2_D_mR, M2_Q_mR, M2_U_mR, M2_H_mR, mu_mR, B_mR)

   Call ParameterstoG2( gauge_mR, y_l_mR, y_nu_mR, y_d_mR, y_u_mR, Mi_mR &
          & , A_l_mR, A_nu_mR, A_d_mR, A_u_mR, M2_E_mR, M2_L_mR, M2_R_mR     &
          & , M2_D_mR, M2_Q_mR, M2_U_mR, M2_H_mR, mu_mR, B_mR, g2b)


   g_out2(1+i1,:) = g2b
   tz = Log(MnuR(3)/mGUT)
   dt = - tz / Real(17, dp)
   Do i1=len2-18,len2-2
    t =  tz + dt * (i1 - len2 + 18)
    Qvec(i1+1) = Mgut * Exp(t)
    Call rkstp(dt,t,g2a,rge213,w2)
    g_out(2+i1,:) = g2a
    t =  tz + dt * (i1 - len2 + 18)
    Call rkstp(dt,t,g2b,rge267,w2b)
    g_out2(2+i1,:) = g2b

   End Do

  else

   Do i1=0,len2-2
    t =  tz + dt * i1
    Qvec(i1+1) = Mgut * Exp(t)
    Call rkstp(dt,t,g2a,rge213,w2)
    g_out(2+i1,:) = g2a
   End Do
  end if

  Qvec(len2) = Mgut

 Iname = Iname - 1
 
 End Subroutine RunRGEup


 Subroutine RunRGEup2(lenR, lenQ, g2, Qi, Qf, Qvec, g_out)
 !-----------------------------------------------------------------------
 ! Uses Runge-Kutta method to integrate RGE's from Qi to Qf
 ! input:
 !   lenR .. length of data vector
 !   lenQ .. length of Q vector 
 !   g2 .... initial data
 !   Qi .... starting scale
 !   Qf .... final scale
 ! output:
 !   Qvec .. vector containing the scales
 !   g_out.. vector containing the data at the various scale
 ! Written by Werner Porod, 17.04.02
 !-----------------------------------------------------------------------
 Implicit None

  Integer, Intent(in) :: lenR, lenQ
  Real(dp), Intent(in) :: g2(lenR), Qi, Qf
  Real(dp), Intent(out) :: g_out(lenR,lenQ), Qvec(lenQ)
  
  Integer:: i1
  Real(dp) :: g2a(lenR), w2(lenR,3), tz, dt, t

  Iname = Iname + 1
  NameOfUnit(Iname) = 'RunRGEup2'

  tz = Log(Qi/Qf)
  dt = - tz / Real(lenQ-1, dp)
  g2a = g2
  !------------------
  ! now the running
  !------------------
  g_out(:,1) = g2a
  Qvec(1) = Qi
  Do i1=0,lenQ-2 
   t =  tz + dt * i1
   Qvec(i1+1) = Qf * Exp(t)
   if (lenR.eq.180) Call rkstp(dt,t,g2a,rge_SU5,w2)
   if (lenR.eq.213) Call rkstp(dt,t,g2a,rge213,w2)
   if (lenR.eq.267) Call rkstp(dt,t,g2a,rge267,w2)
   if (lenR.eq.285) Call rkstp(dt,t,g2a,rge285,w2)
   g_out(:,2+i1) = g2a
  End Do

  Qvec(lenQ) = Qf

 Iname = Iname - 1
 
 End Subroutine RunRGEup2



 Logical Function SetCheckSugraDetails(V1, V2, V3, V4, V5)
 !----------------------------------------------------------------------------
 ! Sets the variable CheckSugraDetails which controls writing of the details
 ! during the run. Default is .False. In case that one of the entries .True.
 ! the following action is performed:
 ! CheckSugraDetails(1) -> write high scale values for gauge and Yukawa
 !                         couplings to channel 10 for each iteration
 ! CheckSugraDetails(2) -> write low scale values for gauge and Yukawa
 !                         couplings to channel 10 for each iteration
 ! CheckSugraDetails(3) -> write high scale values for soft SUSY parameters
 !                         to channel 10 for each iteration
 ! CheckSugraDetails(4) -> write low scale values for soft SUSY parameters
 !                         to channel 10 for each iteration
 ! CheckSugraDetails(5) -> write inital low scale values for gauge and Yukawa
 !                         couplings to channel 10 for each iteration
 ! Written by Werner Porod, 24..09.01
 !----------------------------------------------------------------------------
 Implicit None
  Logical, Intent(in) :: V1, V2, V3, V4, V5
   SetCheckSugraDetails = .False.
   CheckSugraDetails(1) = V1
   CheckSugraDetails(2) = V2
   CheckSugraDetails(3) = V3
   CheckSugraDetails(4) = V4
   CheckSugraDetails(5) = V5
   SetCheckSugraDetails = .True.
 End Function SetCheckSugraDetails


 Subroutine SetGUTScale(scale)
 Implicit None
  Real(dp), Intent(in) :: scale

  If (scale.Lt.0._dp) Then
   UseFixedGUTScale = .False.
  Else
   UseFixedGUTScale = .True.
   GUT_scale = scale
  End If

 End Subroutine SetGUTScale


 Logical Function SetHighScaleModel(model)
  Implicit None
  Character(len=*), Intent(in) :: model

  SetHighScaleModel = .False.
  HighScaleModel = model
  SetHighScaleModel = .True.
 End  Function SetHighScaleModel

 Subroutine SetRGEScale(scale)
 Implicit None
  Real(dp), Intent(in) :: scale

  Real(dp) :: old_scale

  If (scale.Lt.0._dp) Then
   UseFixedScale = .False.
  Else
   UseFixedScale = .True.
   old_scale = SetRenormalizationScale(scale)
  End If

 End Subroutine SetRGEScale

 Logical Function SetStrictUnification(V1)
 !-----------------------------------------------------------------------
 ! Sets the parameter StrictUnification, which enforces g_3 = g_1 = g_2
 ! at the high scale, default is .false.
 ! written by Werner Porod, 24.09.01
 !-----------------------------------------------------------------------
 Implicit None
  Logical, Intent(in) :: V1
  SetStrictUnification = .False.
  StrictUnification = V1
  SetStrictUnification = .True.
 End Function SetStrictUnification


 Integer Function SetYukawaScheme(V1)
 !-----------------------------------------------------------------------
 ! Sets the parameter YukawaScheme, which controls wheter the top (=1) or the
 ! down (=2) Yukawa couplings stay diagonal at the low scale 
 ! written by Werner Porod, 20.11.01
 !-----------------------------------------------------------------------
 Implicit None
  Integer, Intent(in) :: V1
  SetYukawaScheme = YukawaScheme
  YukawaScheme = V1
 End Function SetYukawaScheme

 Subroutine Sugra(delta, vevSM, mC, U, V, mN, N, mS0, mS02, RS0, mP0, mP02,RP0&
    & , mSpm, mSpm2, RSpm, mDsquark, mDsquark2, RDsquark, mUsquark, mUsquark2 &
    & , RUsquark, mSlepton, mSlepton2, RSlepton, mSneutrino, mSneutrino2      &
    & , RSneutrino, mGlu, phase_glu, gauge, uL_L, uL_R, uD_L, uD_R, uU_L      &
    & , uU_R, Y_l, Y_d  &
    & , Y_u, Mi, A_l, A_d, A_u, M2_E, M2_L, M2_D, M2_Q, M2_U, M2_H, mu, B     &
    & , mGUT, kont, WriteComment, niter)
 !-----------------------------------------------------------------------
 ! Computes RGE's of the the SUSY parameters 
 ! Uses Runge-Kutta method to integrate RGE's from M_Z to M_GUT
 ! and back, putting in correct thresholds. For the first iteration
 ! only the first 6 couplings are included and a common threshold
 ! is used.
 ! written by Werner Porod, 4.8.1999
 ! 24.09.01: portation to f90
 !           taking masses as input to see whether situation improves
 !           in principal they can be zero, but this in general requires
 !           one additional run. therefore a good educated guess is
 !           useful. The parameters might be generated with the help
 !           of the routine FirstGuess which are then plugged into
 !           TreeMasses
 !         - Contrary to the old version I put now the calculation of the
 !           tree level masses to the routine LoopMasses
 ! 16.11.01: including logical variable WriteComment to get a better control
 !           on the various steps
 ! 16.09.02: the electroweak scale is now put here, except it has already
 !           been fixed in the main program
 ! 05.01.04: calculating now gauge and Yukawa couplings at m_Z using
 !           running masses, more Yukawa couplings from the previous run
 !           are taken as starting point for the next run
 !-----------------------------------------------------------------------
 Implicit None

  Logical, Intent(in) ::  WriteComment
  Integer, Intent(in) :: niter
  Integer, Intent(inout) :: kont
  Real(dp), Intent(in) :: delta
  Real(dp), Intent(inout) :: vevSM(2)
  Real(dp), Intent(out) :: mGUT
  Real(dp), Intent(inout) :: mC(:), mN(:), mS0(:), mP0(:), mSpm(:) &
    & , mUsquark(:), mDsquark(:), mSlepton(:), mSneutrino(:)       &
    & , mUsquark2(:), mDsquark2(:), mSlepton2(:), mSneutrino2(:)   &
    & , mS02(:), mP02(:), mSpm2(:), RP0(:,:), RS0(:,:), mglu
  Complex(dp), Intent(inout) :: U(:,:), V(:,:), N(:,:), RSpm(:,:)      &
    & , RDsquark(:,:), RUsquark(:,:), RSlepton(:,:), RSneutrino(:,:)   &
    & , phase_Glu
  Real(dp), Intent(inout) :: gauge(3), M2_H(2)
  Complex(dp), Dimension(3,3), Intent(inout) :: Y_l, Y_d, Y_u, A_l, A_d, A_u &
          & , M2_E, M2_L, M2_D, M2_Q, M2_U, uL_L, uL_R, uU_L, uU_R, uD_L, uD_R
  Complex(dp), intent(inout) :: Mi(3), mu, B

  Real(dp) :: deltag0, tanb, g0(213), t1, t2, mZ2_run, mW2_run, g1(57) &
    & , mc2(2), mn2(4), mudim, tz, dt, mc2_T(2), mn2_T(4), vev, sinW2
  Integer :: j, n_C, n_N, n_S0, n_P0, n_Spm, n_Su, n_Sd, n_Sl &
    & , n_Sn, i1, n_tot
  Real(dp) :: mC_T(2), mN_T(4), mS0_T(2), mP0_T(2), mSpm_T(2)              &
    & , mUsquark_T(6), mDsquark_T(6), mSlepton_T(6), mSneutrino_T(3)       &
    & , mUsquark2_T(6), mDsquark2_T(6), mSlepton2_T(6), mSneutrino2_T(3)   &
    & , mS02_T(2), mP02_T(2), mSpm2_T(2), RP0_T(2,2), RS0_T(2,2), mglu_T
  Complex(dp) :: U_T(2,2), V_T(2,2), N_T(4,4), RSpm_T(2,2)                    &
    & , RDsquark_T(6,6), RUsquark_T(6,6), RSlepton_T(6,6), RSneutrino_T(3,3)  &
    & , phase_Glu_T

  Logical :: FoundResult
  Real(dp), Allocatable :: mass_new(:), mass_old(:), diff_m(:)
   
  Iname = Iname + 1
  NameOfUnit(Iname) = 'Sugra'
  !-----------------
  ! Inititalization
  !-----------------
  kont = 0 
  FoundResult = .False.
  tanb = vevSM(2) / vevSM(1)
  !--------------------------------------------------------------------
  ! saving masses for checking + creation of corresponding variables
  !-------------------------------------------------------------------
  n_C = Size( mC )
  n_N = Size( mN )
  n_S0 = Size( mS0 )
  n_P0 = Size( mP0 )
  n_Spm = Size( mSpm )
  n_Su = Size( mUsquark )
  n_Sd = Size( mDsquark )
  n_Sl = Size( mSlepton )
  n_Sn = Size( mSneutrino )
  n_tot = 1 + n_C + n_N + n_S0 + n_P0 + n_Spm + n_Su + n_Sd + n_Sl + n_Sn
  Allocate( mass_old( n_tot ), mass_new( n_tot ), diff_m( n_tot) )
  mass_old(1) = mGlu
  n_tot = 1
  mass_old(n_tot+1:n_tot+n_C) = mC
  n_tot = n_tot + n_C
  mass_old(n_tot+1:n_tot+n_N) = mN
  n_tot = n_tot + n_N
  mass_old(n_tot+1:n_tot+n_S0) = mS0
  n_tot = n_tot + n_S0
  mass_old(n_tot+1:n_tot+n_P0) = mP0
  n_tot = n_tot + n_P0
  mass_old(n_tot+1:n_tot+n_Spm) = mSpm
  n_tot = n_tot + n_Spm
  mass_old(n_tot+1:n_tot+n_Su) = mUsquark
  n_tot = n_tot + n_Su
  mass_old(n_tot+1:n_tot+n_Sd) = mDsquark
  n_tot = n_tot + n_Sd
  mass_old(n_tot+1:n_tot+n_Sl) = mSlepton
  n_tot = n_tot + n_Sl
  mass_old(n_tot+1:n_tot+n_Sn) = mSneutrino

  !-----------------------------------------------------------------
  ! first setting of renormalization scale, if it is not yet fixed 
  ! somewhere else
  ! I take here the geometric mean of the stop masses
  !-----------------------------------------------------------------
  If (.not.UseFixedScale) Then
   if (GenerationMixing) then
    mudim = 1._dp
    Do j=1,6
     If ( (Abs(RUsquark(j,3))**2 + Abs(RUsquark(j,6))**2).gt.0.6_dp) &
      & mudim = mudim * mUSquark(j)
    end do
   else
    mudim = Max(mZ**2, mUSquark(5) * mUSquark(6) )
   end if
   call SetRGEScale(mudim)
   UseFixedScale = .False.
  end if
  !-----------------------------------------------------
  ! running of RGEs
  ! iterate entire process
  !-----------------------------------------------------
  Do j=1,niter
   !-------------------------------------
   ! boundary condition at the EW-scale
   !-------------------------------------
   If (WriteComment) Write(*,*) "Sugra",j
   call cpu_time(t1)
   !---------------------------------------------------
   ! the use of the Yukawas of the previous run works
   ! currently only in case of no generation mixing
   !---------------------------------------------------
   Call BoundaryEW(j, vevSM, mC, U, V, mN, N, mS02, RS0, mP02, RP0, mSpm, mSpm2 &
    & , RSpm, mDsquark, mDsquark2, RDsquark, mUsquark, mUsquark2, RUsquark    &
    & , mSlepton, mSlepton2, RSlepton, mSneutrino2, RSneutrino                &
    & , uU_L, uU_R, uD_L, uD_R, uL_L, uL_R, mGlu, phase_glu, mZ2_run, mW2_run &
    & , delta, g1, kont)

   if (kont.ne.0) then
    Iname = Iname - 1
    Deallocate(mass_old, mass_new, diff_m  )
    return
   end if
   call cpu_time(t2)
   If (WriteComment) Write(*,*) "BoundaryEW",t2-t1
   !-----------------
   ! now the running
   !-----------------
   Call RunRGE(kont, 0.1_dp*delta, vevSM, g1, g0, mGUT)
   call cpu_time(t1)
   If (WriteComment) Write(*,*) "RunRGE",t1-t2
   If (kont.Ne.0) Then
    Iname = Iname - 1
    Deallocate(mass_old, mass_new, diff_m  )
    Return
   End If

   Call GToParameters(g0, gauge, Y_l, Y_d, Y_u, Mi, A_l, A_d, A_u &
                  & , M2_E, M2_L, M2_D, M2_Q, M2_U, M2_H, mu, B)

   !----------------------------------------------------------------
   ! the RGE paper defines the Yukawas transposed to my conventions
   ! renormalize g_1 to g_Y
   !----------------------------------------------------------------
   Y_u = Transpose(Y_u)
   Y_d = Transpose(Y_d)
   Y_l = Transpose(Y_l)
   A_u = Transpose(A_u)
   A_d = Transpose(A_d)
   A_l = Transpose(A_l)
   gauge(1) = Sqrt(3._dp / 5._dp ) * gauge(1)

   Call LoopMassesMSSM(delta, tanb, gauge, Y_l, Y_d, Y_u, Mi, A_l, A_d, A_u  &
    & , M2_E, M2_L, M2_D, M2_Q, M2_U, M2_H, phase_mu, mu, B, j                &
    & , uU_L, uU_R, uD_L, uD_R, uL_L, uL_R                                    &
    & , mC, mC2, U, V, mN, mN2, N, mS0, mS02, RS0, mP0, mP02, RP0             &
    & , mSpm, mSpm2, RSpm, mDsquark, mDsquark2, RDsquark, mUsquark, mUsquark2 &
    & , RUsquark, mSlepton, mSlepton2, RSlepton, mSneutrino, mSneutrino2      &
    & , RSneutrino, mGlu, phase_glu, kont)
   g0(210) = Real(mu,dp)
   g0(211) = Aimag(mu)
   g0(212) = Real(B,dp)
   g0(213) = Aimag(B)
   call cpu_time(t2)
   If (WriteComment) Write(*,*) "LoopMasses",t2-t1

   If (kont.Ne.0) Then
    Iname = Iname - 1
    Deallocate(mass_old, mass_new, diff_m  )
    Return
   End If
   
   !-------------------
   ! comparing masses
   !-------------------
   mass_new(1) = mGlu
   n_tot = 1
   mass_new(n_tot+1:n_tot+n_C) = mC
   n_tot = n_tot + n_C
   mass_new(n_tot+1:n_tot+n_N) = mN
   n_tot = n_tot + n_N
   mass_new(n_tot+1:n_tot+n_S0) = mS0
   n_tot = n_tot + n_S0
   mass_new(n_tot+1:n_tot+n_P0) = mP0
   n_tot = n_tot + n_P0
   mass_new(n_tot+1:n_tot+n_Spm) = mSpm
   n_tot = n_tot + n_Spm
   mass_new(n_tot+1:n_tot+n_Su) = mUsquark
   n_tot = n_tot + n_Su
   mass_new(n_tot+1:n_tot+n_Sd) = mDsquark
   n_tot = n_tot + n_Sd
   mass_new(n_tot+1:n_tot+n_Sl) = mSlepton
   n_tot = n_tot + n_Sl
   mass_new(n_tot+1:n_tot+n_Sn) = mSneutrino

   diff_m = abs(mass_new - mass_old)
   Where (Abs(mass_old).Gt.0._dp) diff_m = diff_m / Abs(mass_old)
 
   deltag0 = MaxVal( diff_m )

   If (WriteComment) Write(*,*) "Sugra,Comparing",deltag0

   If ((deltag0.Lt.delta).and.(j.gt.1)) Then ! require at least two iterations
    FoundResult = .True.
    Exit
   Else
    mass_old = mass_new
    !----------------------------------------------------------------
    ! recalculating massses at tree level; this is needed as input
    ! for BoundaryEW
    ! first running down to m_Z
    !----------------------------------------------------------------
    If (WriteComment) Write(*,*) "Sugra, Tree level masses",deltag0
    mudim = GetRenormalizationScale()
    tz = 0.5_dp * Log(mZ2/mudim)
    dt = tz / 100._dp

    Call odeint(g0, 213, 0._dp, tz, delta, dt, 0._dp, rge213, kont)

    Call GToParameters(g0, gauge, Y_l, Y_d, Y_u, Mi, A_l, A_d, A_u &
                  & , M2_E, M2_L, M2_D, M2_Q, M2_U, M2_H, mu, B)
    Y_u = Transpose(Y_u)
    Y_d = Transpose(Y_d)
    Y_l = Transpose(Y_l)
    A_u = Transpose(A_u)
    A_d = Transpose(A_d)
    A_l = Transpose(A_l)
    gauge(1) = Sqrt(3._dp / 5._dp ) * gauge(1)

    sinW2 = 1._dp - mW2 / mZ2
    vev =  Sqrt( mZ2 * (1._dp - sinW2) * SinW2 / (pi * alpha_mZ) )
    vevSM(1) = vev / Sqrt(1._dp + tanb_mZ**2)
    vevSM(2) = tanb_mZ * vevSM(1)

    Call TreeMassesMSSM2(gauge(1), gauge(2), vevSM, Mi(1), Mi(2), Mi(3)      &
     & , mu, B, tanb, M2_E, M2_L, A_l, Y_l, M2_D, M2_U, M2_Q, A_d, A_u       &
     & , Y_d, Y_u, uU_L, uU_R, uD_L, uD_R, uL_L, uL_R                        &
     & , mGlu_T, Phase_Glu_T, mC_T, mC2_T, U_T, V_T, mN_T, mN2_T, N_T        &
     & , mSneutrino_T, mSneutrino2_T, Rsneutrino_T, mSlepton_T, mSlepton2_T  &
     & , RSlepton_T, mDSquark_T, mDSquark2_T, RDSquark_T, mUSquark_T         &
     & , mUSquark2_T, RUSquark_T, mP0_T, mP02_T, RP0_T, mS0_T, mS02_T, RS0_T &
     & , mSpm_T, mSpm2_T, RSpm_T, mZ2_run, mW2_run, GenerationMixing, kont   &
     & , .False., .False.)

    If (kont.Ne.0) Then
     Iname = Iname - 1
     Deallocate(mass_old, mass_new, diff_m  )
     Return
    End If

    !-----------------------------------------------------------------
    ! setting of renormalization scale, if it is not yet fixed 
    ! somewhere else
    ! I take here the geometric mean of the stop masses
    !-----------------------------------------------------------------
    If (.not.UseFixedScale) Then
     if (GenerationMixing) then
      mudim = 1._dp
      Do i1=1,6
       If ( (Abs(RUsquark(i1,3))**2 + Abs(RUsquark(i1,6))**2).gt.0.6_dp) &
        & mudim = mudim * mUSquark(i1)
      end do
     else
      mudim = Max(mZ**2, mUSquark(5) * mUSquark(6) )
     end if
     call SetRGEScale(mudim)
     UseFixedScale = .False.
    end if

    !-------------------------------------------------------------------
    ! checking if at tree level all masses squared are positiv and above
    ! approximately 0.9*m_Z at m_Z (the latter is for numerical stability),
    ! if not, the on-shell masses will be used 
    !-------------------------------------------------------------------
    If (Min(Minval(mUsquark2_T), Minval(mDSquark2_T), Minval(mSlepton2_T)   &
     &    , Minval(mSneutrino2_T), Minval(mS02_T), Minval(mP02_T)           &
     &    , Minval(mSpm2_T)).Gt. 5000._dp ) Then ! more than ~mZ^2/2
     mGlu = mGlu_T
     Phase_Glu = Phase_Glu_T
     mC = mC_T
     mC2 = mC2_T
     U = U_T
     V = V_T
     mN = mN_T
     mN2 = mN2_T
     N = N_T
     mSneutrino = mSneutrino_T
     mSneutrino2 = mSneutrino2_T
     Rsneutrino = Rsneutrino_T
     mSlepton = mSlepton_T
     mSlepton2 = mSlepton2_T
     RSlepton = RSlepton_T
     mDSquark = mDSquark_T
     mDSquark2 = mDSquark2_T
     RDSquark = RDSquark_T
     mUSquark = mUSquark_T
     mUSquark2 = mUSquark2_T
     RUSquark = RUSquark_T
     mP0 = mP0_T
     mP02 = mP02_T
     RP0 = RP0_T
     mS0 = mS0_T
     mS02 = mS02_T
     RS0 = RS0_T
     mSpm = mSpm_T
     mSpm2 = mSpm2_T
     RSpm = RSpm_T
     YukScen = 1
    else
     YukScen = 2
     kont = 0
    End If
   End If

  End Do

  If (.Not. FoundResult ) Then
   Write (ErrCan,*) 'Warning from subroutine Sugra, no convergence has'
   Write (ErrCan,*) 'has been found after',niter,' iterations.'
   Write (ErrCan,*) 'required delta',delta 
   Write (ErrCan,*) 'found delta',deltag0
   kont = -405
  End If

  Deallocate( mass_old, mass_new, diff_m )

  Iname = Iname - 1

 End Subroutine Sugra

End Module SugraRuns
