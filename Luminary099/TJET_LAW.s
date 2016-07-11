# Copyright:	Public domain.
# Filename:	TJET_LAW.agc
# Purpose: 	Part of the source code for Luminary 1A build 099.
#		It is part of the source code for the Lunar Module's (LM)
#		Apollo Guidance Computer (AGC), for Apollo 11.
# Assembler:	yaYUL
# Contact:	Ron Burkey <info@sandroid.org>.
# Website:	www.ibiblio.org/apollo.
# Pages:	1460-1469
# Mod history:	2009-05-27 RSB	Adapted from the corresponding 
#				Luminary131 file, using page 
#				images from Luminary 1A.
#		2009-06-06 RSB	Eliminated a stray instruction that had crept
#				in somehow.
#
# This source code has been transcribed or otherwise adapted from
# digitized images of a hardcopy from the MIT Museum.  The digitization
# was performed by Paul Fjeld, and arranged for by Deborah Douglas of
# the Museum.  Many thanks to both.  The images (with suitable reduction
# in storage size and consequent reduction in image quality as well) are
# available online at www.ibiblio.org/apollo.  If for some reason you
# find that the images are illegible, contact me at info@sandroid.org
# about getting access to the (much) higher-quality images which Paul
# actually created.
#
# Notations on the hardcopy document read, in part:
#
#	Assemble revision 001 of AGC program LMY99 by NASA 2021112-61
#	16:27 JULY 14, 1969 

# Page 1460
# PROGRAM DESCRIPTION
# DESIGNED BY:	R. D. GOSS AND P. S. WEISSMAN
# CODED BY:  P. S. WEISSMAN, 28 FEBRUARY 1968
#
# TJETLAW IS CALLED AS A SUBROUTINE WHEN THE LEM IS NOT DOCKED AND THE AUTOPILOT IS IN THE AUTOMATIC OR
# ATTITUDE-HOLD MODE TO CALCULATE THE JET-FIRING-TIME (TJET) REQUIRED FOR THE AXIS INDICATED BY AXISCTR:
#	-1	INDICATES THE P-AXIS
#	+0	INDICATES THE U-AXIS
#	+1	INDICATES THE V-AXIS
# THE REGISTERS E AND EDOT CONTAIN THE APPROPRIATE ATTITUDE ERROR AND ERROR RATE AND SENSETYP SHOWS WHETHER
# UNBALANCED COUPLES ARE PREFERRED.  TJETLAW ALSO USES VARIOUS FUNCTIONS OF ACCELERATION AND DEADBAND WHICH ARE
# COMPUTED IN THE 1/ACCONT SECTION OF 1/ACCS AND ARE STORED IN SUCH AN ORDER THAT THEY CAN BE CONVENIENTLY
# ACCESSED BY INDEXING.
#
# THE SIGN OF THE REQUIRED ROTATION IS CARRIED THROUGH TJETLAW AS ROTSENSE AND IS FINALLY APPLIED TO TJET JUST
# PREVIOUS TO ITS STORAGE IN THE LOCATION CORRESPONDING TO THE AXIS (TJP, TJU, OR TJV).  THE NUMBER OF JETS THAT
# TJETLAW ASSUMES WILL BE USED AS INDICATED BY THE SETTING OF NUMBERT FOR THE U- OR V-AXIS.  TWO JETS ARE ALWAYS
# ASSUMED FOR THE P-AXIS ALTHOUGH FOUR JETS WILL BE FIRED WHEN FIREFCT IS MORE NEGATIVE THAN -4.0 DEGREES
# (FIREFCT IS THE DISTANCE TO A SWITCH CURVE IN THE PHASE PLANE) AND A LONG FIRING IS CALLED FOR.
#
# IN ORDER TO AVOID SCALING DIFFICULTIES, SIMPLE ALGORITHMS TAGGED RUFLAW1, -2 AND -3 ARE RESORTED TO WHEN THE
# ERROR AND/OR ERROR RATE ARE LARGE.
#
# CALLING SEQUENCE:
#		TC	TJETLAW		# (MUST BE IN JASK)
#	OR
#		INHINT			# (MUST BE IN JASK)
#		TC	IBNKCALL
#		CADR	TJETLAW
#		RELINT
#
# EXIT:		RETURN TO Q.
#
# INPUT:
#	FROM THE CALLER:  E, EDOT, AXISCTR, SENSETYP, TJP, -U, -V.
#	FROM 1/ACCONT:  48 ERASABLES BEGINNING AT BLOCKTOP (INCLUDING FLAT, ZONE3LIM AND ACCSWU, -V).
#
# OUTPUT:
#	TJP, -U OR -V, NUMBERT (DAPTEMP5), FIREFCT (DAPTEMP3).
#
# DEBRIS:
#	A, L, Q, E, EDOT, DAPTEMP1-6, DAPTEMP1-4.
#
# ALARM:  NONE

		BANK	17
		SETLOC	DAPS2
		BANK
		EBANK=	TJP
# Page 1461
		COUNT*	$$/DAPTJ

TJETLAW		EXTEND			# SAVE Q FOR RETURN.
		QXCH	HOLDQ

# SET INDEXERS TO CORRESPOND TO THE AXIS AND TO THE SIGN OF EDOT

		INDEX	AXISCTR		# AXISDIFF(-1)=NO OF LOCATIONS BET P AND U
		CAF	AXISDIFF	# AXISDIFF(0)=0
		TS	ADRSDIF1	# AXISDIFF(+1)=NO OF LOCATIONS BET V AND U

		CAE	EDOT		# IF EDOT NEGATIVE, PICK UP SET OF VALUES
		EXTEND			#	THAT ALLOW USE OF SAME CODING AS FOR
		BZMF	NEGEDOT		#	POSITIVE EDOT.
		CAE	ADRSDIF1	# SET A SECOND INDEXER WHICH MAY BE
		TS	ADRSDIF2	# 	MODIFIED BY A DECISION FOR MAX JETS.
		CAF	SENSOR		# FOR POSITIVE EDOT, ROTSENSE IS
		TCF	SETSENSE	# 	INITIALIZED POSITIVE.

NEGEDOT		CS	E		# IN ORDER FOR NEG EDOT CASE TO USE CODING
		TS	E		#	OF POS EDOT, MUST MODIFY AS FOLLOWS:
		CS	EDOT		#	1. COMPLEMENT E AND EDOT.
		TS	EDOT		#	2. SET SENSE OF ROTATION TO NEGATIVE
		CAF	BIT1		#	   (REVERSED LATER IF NECESSARY).
		ADS	ADRSDIF1	#	3. INCREMENT INDEXERS BY ONE SO THAT
		TS	ADRSDIF2	#	   THE PROPER PARAMETERS ARE ACCESSED.
		CS	SENSOR
SETSENSE	TS	ROTSENSE

# TEST MAGNITUDE OF E (ATTITUDE ERROR, SINGLE-PRECISION, SCALED AT PI RADIANS):
#	IF GREATER THAN (OR EQUAL TO) PI/16 RADIANS, GO TO THE SIMPLIFIED TJET ROUTINE.
#	IF LESS THAN PI/16 RADIANS, RESCALE TO PI/4

		CAE	E		# PICK UP ATTITUDE ERROR FOR THIS AXIS
		EXTEND
		MP	BIT5		# SHIFT RIGHT TEN BITS:  IF A-REGISTER IS
		CCS	A		#	ZERO, RESCALE AND TEST EDOT.
		TCF	RUFLAW2
		TCF	SCALEE
		TCF	RUFLAW1
SCALEE		CAF	BIT13		# ERROR IS IN L SCALED AT PI/16.  RESCALE
		EXTEND			#	IT TO PI/4 AND SAVE IT.
		MP	L
		TS	E

# TEST MAGNITUDE OF EDOT (ERROR RATE SCALED AT PI/4 RADIANS/SECOND)
#	IF GREATER THAN (OR EQUAL TO) PI/32 RADIANS/SECOND, GO TO THE SIMPLIFIED TJET ROUTINE.
#	IF LESS THAN PI/32 RADIANS/SECOND, THEN RESCALE TO PI/32 RADIANS/SECOND.

		CAE	EDOT		# PICK UP SINGLE-PRECISION ERROR-RATE
# Page 1462
		EXTEND			# FOR THIS AXIS=
		MP	BIT4		# SHIFT RIGHT ELEVEN BITS, IF THE A-REG IS
		EXTEND			# ZERO, THEN RESCALE AND USE FINELAW.
		BZF	SCALEDOT
		TCF	RUFLAW3

# *** FINELAW STARTS HERE ***

SCALEDOT	LXCH	EDOT		# EDOT IS SCALED AT PI/32 RADIANS/SECOND.

		CAE	EDOT		# COMPUTE (EDOT)(EDOT)
		EXTEND
		SQUARE			# PRODUCT SCALED AT PI(2)/2(10) RAD/SEC.
		EXTEND
		MP	BIT13		# SHIFT RIGHT TWO BITS TO RESCALE TO EDOTSQ
		TS	EDOTSQ		#	TO PI(2)/2(8) RAD(2)/SEC(2).

ERRTEST		CCS	E		# DOES BIG ERROR (THREE DEG BEYOND THE
		AD	-3DEG		# DEADBAND) REQUIRE MAXIMUM JETS?
		TCF	+2
		AD	-3DEG
		EXTEND
		INDEX	ADRSDIF1
		SU	FIREDB
		EXTEND
		BZMF	SENSTEST	# IF NOT:  ARE UNBALANCED JETS PREFERRED?
MAXJETS		CAF	TWO		# IF YES:  INCREMENT ADDRESS LOCATOR AND
		ADS	ADRSDIF2	#	   SET SWITCH FOR JET SELECT LOGIC TO 4.
		CAF	FOUR		#	   (ALWAYS DO THIS FOR P-AXIS)
		TCF	TJCALC
SENSTEST	CCS	SENSETYP	# DOES TRANSLATION PREFER MIN JETS.
		TCF	TJCALC		# YES.  USE MIN-JET PARAMETERS
		TCF	MAXJETS		# NO.  GET THE MAX-JET PARAMETERS.
TJCALC		TS	NUMBERT		# SET TO +0,1,4 FOR (U,V-AXES) JET SELECT.

# BEGINNING OF TJET CALCULATIONS:

		CS	EDOTSQ		# SCALED AT PI(2)/2(8).
		EXTEND
		INDEX	ADRSDIF2
		MP	1/ANET1		# .5/ACC SCALED AT 2(6)/PI SEC(2)/RADIAN.
		INDEX	ADRSDIF1
		AD	FIREDB		# DEADBAND SCALED AT PI/4 RADIAN.
		EXTEND
		SU	E		# ATTITUDE ERROR SCALED AT PI/4 RADIAN.
		TS	FIREFCT		# -E-.5(EDOTSQ)/ACC-DB AT PI/4 RADIAN.
		EXTEND
		BZMF	ZON1,2,3

ZONE4,5		INDEX	ADRSDIF1
		CAE	1/ACOAST	# .5/ACC SCALED AT 2(6)/PI WHERE
# Page 1463		
		EXTEND			# ACC = MAX(AMIN, AOS-).
		MP	EDOTSQ		# SCALED AT PI/2(8).
		AD	E		# SCALED AT PI/4
		INDEX	ADRSDIF1
		AD	COASTDB		# SCALED AT PI/4 POS. FOR NEG. INTERCEPT.
		EXTEND			# TEST E+.5(EDOTSQ)/ACC+DB AT PI/4 RADIAN.
		BZMF	ZONE5		# IF FUNCTION NEGATIVE, FIND TJET.
					# IF FUNCTION POSITIVE, IN ZONE 4.

# ZONE 4 IS THE COAST REGION.  HOWEVER, IF THE JETS ARE ON AND DRIVING TOWARD
#	A. THE AXIS WITHIN + OR - (DB + FLAT) FOR DRIFTING FLIGHT, OR
#	B. THE USUAL TARGET PARABOLA FOR POWERED FLIGHT
# THEN THE THRUSTERS ARE KEPT ON.

ZONE4		INDEX	AXISCTR		# IS THE CURRENT VALUE IN TJET NON-ZERO
		CS	TJETU		# 	WITH SENSE OPPOSITE TO EDOT,
		EXTEND			#	(I.E., ARE JETS ON AND FIRING TOWARD
		MP	ROTSENSE	#	THE DESIRABLE STATE).
		EXTEND
		BZMF	COASTTJ		# NO.  COAST.

JETSON		CCS	FLAT		# YES.  IS THIS DRIFTING OR POWERED FLIGHT?
		TCF	DRIFT/ON	# DRIFTING.  GO MAKE FURTHER TEST.

		CS	FIREFCT		# POWERED (OR ULLAGE).  CAN TARGET PARABOLA
		INDEX	ADRSDIF1	#	BE REACHED FROM THIS POINT IN THE
		AD	AXISDIST	#	PHASE PLANE?
		EXTEND
		BZMF	COASTTJ		# NO. SET TJET = 0.
		TC	Z123COMP	# YES.  CALCULATE TJET AS THOUGH IN ZONE 1
		CAE	FIREFCT		#	AFTER COMPUTING THE REQUIRED
		TCF	ZONE1		#	PARAMETERS.

DRIFT/ON	INDEX	ADRSDIF1	# CAN TARGET STRIP OF AXIS BE REACHED FROM
		CS	FIREDB		#	THIS POINT IN THE PHASE PLANE?
		DOUBLE
		AD	FIREFCT
		EXTEND
		BZMF	+3
COASTTJ		CAF	ZERO		# NO.  SET TJET = 0.
		TCF	RETURNTJ

		TC	Z123COMP	# YES. CALCULATE TJET AS THOUGH IN ZONE 2
		TCF	ZONE2,3		#	OR 3 AFTER COMPUTING REQUIRED VALUES.

ZONE5		TS	L		# TEMPORARILY STORE FUNCTION IN L.
		CCS	ROTSENSE	# MODIFY ADRSDIF2 FOR ACCESSING 1/ANET2
		TCF	+4		# AND ACCFCTZ5, WHICH MUST BE PICKED UP
		TC	CCSHOLE		# FROM THE NEXT LOWER REGISTER IF THE
		CS	TWO		# (ACTUAL) ERROR RATE IS NEGATIVE.
# Page 1464		
		ADS	ADRSDIF2

	+4	CAE	L
		EXTEND
		INDEX	ADRSDIF2	# TTOAXIS AND HH ARE THE PARAMETERS UPON
		MP	ACCFCTZ5	#	WHICH THE APPROXIMATIONS TO TJET ARE
		DDOUBL			#	ABASED.
		DDOUBL
		DXCH	HH		# DOUBLE PRECISION H SCALED AT 8 SEC(2).
		INDEX	ADRSDIF2
		CAE	1/ANET2		# SCALED AT 2(7)/PI SEC(2)/RAD.
		EXTEND
		MP	EDOT		# SCALED AT PI/2(5)
		TS	TTOAXIS		# SCALED AT 4 SEC.

# TEST WHETHER TJET GREATER THAN 50 MSEC.

		EXTEND
		MP	-.05AT2		# H - .05 TTOAXIS - .00125 G.T. ZERO
		AD	HH		# 	(SCALED AT 8 SEC(2) ).
		AD	NEG2
		EXTEND
		BZMF	FORMULA1

# TEST WHETHER TJET GREATER THAN 150 MSEC.

		CAE	TTOAXIS
		EXTEND
		MP	-.15AT2		# H - .15 TTOAXIS - .01125 G.T. ZERO
		AD	HH		#	(SCALED AT 8 SEC(2) )
		AD	-.0112A8
		EXTEND
		BZMF	FORMULA2

# IF TJET GREATER THAN 150 MSEC, ASSIGN IT VALUE OF 250 MSEC, SINCE THIS
# IS ENOUGH TO ASSURE NO SKIP NEXT CSP (100 MSEC).

FULLTIME	CAF	BIT11		# 250 MSEC SCALED AT 4 SEC.

# RETURN TO CALLING PROGRAM WITH JET TIME SCALED AS TIME6 AND SIGNED.

RETURNTJ	EXTEND			# ALL BRANCHES TERMINATE HERE WITH TJET
		MP	ROTSENSE	#	(SCALED AT 4 SEC) IN THE ACCUMULATOR.
		INDEX	AXISCTR		# ROTSENSE APPLIES SIGN AND CHANGES SCALE.
		TS	TJETU
		EXTEND
		INDEX	AXISCTR
		MP	ACCSWU		# SET SWITCH FOR JET SELECT IF ROTATION IS
		CAE	L
		EXTEND			#	IN A SENSE FOR WHICH 1/ACCS HAS FORCED
		BZMF	+3		#	A MAX-JET CALCULATION.
		CAF	FOUR
# Page 1465		
		TS	NUMBERT
		TC	HOLDQ		# RETURN VIA SAVED Q.

# TJET = H/(.025 + TTOAXIS) 	FOR TJET LESS THAN 50 MSEC.

FORMULA1	CS	-.025AT4	# .025 SEC SCALED AT 4.
		AD	TTOAXIS		# SCALED AT 4 SECONDS.
		DXCH	HH		# STORE DENOMINATOR IN FIRST WORD OF H,
		EXTEND			#	WHICH NEED NOT BE PRESERVED.  PICK UP
		DV	HH		#	DP H AND DIVIDE BY DENOMINATOR.
		EXTEND
		MP	BIT14		# RESCALE TJET FROM 2 TO USUAL 4 SEC.
		TCF	CHKMINTJ	# CHECK THAT TJET IS NOT LESS THAN MINIMUM

# TJET = (H + .00375)/(0.1 + TTOAXIS)	FOR TJET GREATER THAN 50 MSEC.

FORMULA2	EXTEND
		DCA	.00375A8	# .00375 SEC(2) SCALED AT 8.
		DAS	HH		# STORE NUMERATOR IN DP H, WHICH NEED NOT
					#	BE PRESERVED.
		CAE	TTOAXIS		# SCALED AT 4 SEC.
		AD	.1AT4		# 0.1 SEC SCALED AT 4.
		DXCH	HH		# STORE DENOMINATOR IN FIRST WORD OF H,
		EXTEND			#	WHICH NEED NOT BE PRESERVED.  PICK UP
		DV	HH		#	DP NUMERATOR AND DIVIDE BY DENOMINATOR
		EXTEND
		MP	BIT14		# RESCALE TJET FROM 2 TO USUAL 4 SEC.
		TCF	RETURNTJ	# END SUBROUTINE.

# SUBROUTINIZED COMPUTATIONS REQUIRED FOR ALL ENTRIES INTO CODING FOR ZONES 1, 2, AND 3.
# REACHED BY TC FROM 3 POINTS IN TJETLAW.

Z123COMP	CS	ROTSENSE	# USED IN RETURNTJ SECTION TO RESCALE TJET
		TS	ROTSENSE	# 	AS TIME6 AND GIVE IT PROPER SIGN.
		CAE	EDOT		# SCALED AT PI/2(5) RAD/SEC.
		EXTEND
		INDEX	ADRSDIF2
		MP	1/ANET1		# SCALED AT 2(7)/PI SEC(2)/RAD.
		TS	TTOAXIS		# STORE TIME-TO-AXIS SCALED AT 4 SECONDS.
		AD	-TJMAX
		EXTEND			# IS TIME TO AXIS LESS THAN 150 MSEC.
		BZMF	+2
		TCF	FULLTIME	# NO. FIRE JETS, DO NOT CALCULATE TJET.
		RETURN			# YES.  GO ON TO FIND TJET

ZON1,2,3	TC	Z123COMP	# SUBROUTINIZED PREPARATION FOR ZONE1,2,3.

# IF THE (NEG) DISTANCE BEYOND PARABOLA IS LESS THAN FLAT, USE SPECIAL
# LOGIC TO ACQUIRE MINIMUM IMPULSE LIMIT CYCLE.  DURING POWERED FLIGHT
# Page 1466
# OR ULLAGE, FLAT = 0

		CAE	FIREFCT		# SCALED AT PI/4 RAD.
		AD	FLAT
		EXTEND
		BZMF	ZONE1		# NOT IN SPECIAL ZONES.

# FIRE FOR AXIS OR, IF CLOSE, FIRE MINIMUM IMPULSE.  IF ON AXIS, COAST.

ZONE2,3		CS	ZONE3LIM	# HEIGHT OF MIN-IMPULSE ZONE SET BY 1/ACCS
		AD	TTOAXIS		#	35 MSEC IN DRIFTING FLIGHT
		EXTEND			#	ZERO WHEN TRYING TO ENTER GTS CONTROL.
		BZMF	ZONE3
ZONE2		CAE	TTOAXIS		# FIRE TO AXIS.
		TCF	RETURNTJ
ZONE3		CCS	EDOT		# CHECK IF EDOT IS ZERO.
		CAF	BIT6		# FIRE A ONE-JET MINIMUM IMPULSE.
		TCF	RETURNTJ	# TJET = +0.
		TC	CCSHOLE		# CANNOT BE BECAUSE NEG EDOT COMPLEMENTED.
		TCF	RETURNTJ	# TJET = +0.

ZONE1		EXTEND
		INDEX	ADRSDIF1
		SU	AXISDIST	# SCALED AT PI/4 RAD.
		EXTEND
		INDEX	ADRSDIF2
		MP	ACCFCTZ1	# SCALED AT 2(7)/PI SEC(2)/RAD.
		DDOUBL
		DDOUBL
		DXCH	HH		# DOUBLE PRECISION H SCALED AT 8 SEC(2).

# TEST WHETHER TOTAL TIME REQUIRED GREATER THAN 150 MSEC:
#	                     2                                   2
# 	IS .5(.150 - TTOAXIS)  - H  NEGATIVE (SCALED AT 8 SECONDS )

		CAE	TTOAXIS		# TTOAXIS SCALED AT 4 SECONDS.
		AD	-TJMAX		# -.150 SECOND SCALED AT 4.
		EXTEND
		SQUARE
		EXTEND
		SU	HH		# HIGH WORD OF H SCALED AT 8 SEC(2).
		EXTEND
		BZMF	FULLTIME	# YES.  NEED NOT CALCULATE TJET.

# TEST WHETHER TIME BEYOND AXIS GREATER THAN 50 MSEC TO DETERMINE WHICH APPROXIMATION TO USE.

		CAE	HH
		AD	NEG2
		EXTEND
		BZMF	FORMULA3

# Page 1467
# TJET = H/0.1 + TTOAXIS + .0375	FOR APPROXIMATION OVER MORE THAN 50 MSEC.

		CAF	.1AT2		# STORE .1 SEC SCALED AT 2 FOR DIVISION.
		DXCH	HH		# DP H SCALED AT 8 SEC(2) NEED NOT BE
		EXTEND			#	PRESERVED.
		DV	HH		# QUOTIENT SCALED AT 4 SECONDS.
		AD	TTOAXIS		# SCALED AT 4 SEC.
		AD	.0375AT4	# .0375 SEC SCALED AT 4.
		TCF	RETURNTJ	# END COMPUTATION.

# TJET - H/.O25 + TTOAXIS 	FOR APPROXIMATION OVER LESS THAN 50 MSEC.

FORMULA3	CS	-.025AT2	# STORE +.25 SEC SCALED AT 2 FOR DIVISION
		DXCH	HH		# PICK UP DP H AT 8, WHICH NEED NOT BE
		EXTEND			# 	PRESERVED.
		DV	HH		# QUOTIENT SCALED AT 4 SECONDS.
		AD	TTOAXIS		# SCALED AT 4 SEC.

# IF COMPUTED JET TIME IS LESS THAN TJMIN, TJET IS SET TO ZERO.
# MINIMUM IMPULSES REQUIRED IN ZONE 3 ARE NOT SUBJECT TO THIS CONSTRAINT, NATURALLY.

CHKMINTJ	AD	-TJMIN		# IS COMPUTED TIME LESS THAN THE MINIMUM.
		EXTEND
		BZMF	COASTTJ		# YES, SET TIME TO ZERO.
		AD	TJMIN		# NO, RESTORE COMPUTED TIME.
		TCF	RETURNTJ	# END COMPUTATION.

# Page 1468
# *** ROUGHLAW ***
#
# BEFORE ENTRY TO RUFLAW:
#	1. INDEXERS ADRSDIF1 AND ADRSDIF2 ARE SET ON BASIS OF AXIS, AND SIGN OF EDOT.
#	2. IF EDOT WAS NEGATIVE, E AND EDOT ARE ROTATED INTO UPPER HALF-PLANE AND ROTSENSE IS MADE NEGATIVE.
#	3. E IS SCALED AT PI RADIANS AND EDOT AT PI/4 RAD/SEC.
#	   (EXCEPT THE RUFLAW3 ENTRY WHEN E IS AT PI/4)
#
# RUFLAW1:	ERROR MORE NEGATIVE THAN PI/16 RAD.  FIRE TO A RATE OF 6.5 DEG/SEC (IF JET TIME EXCEEDS 20 MSEC.).
# RUFLAW2:	ERROR MORE POSITIVE THAN PI/16 RAD.  FIRE TO AN OPPOSING RATE OF 6.5 DEG/SEC.
# RUFLAW3:	ERROR RATE GREATER THAN PI/32 RAD/SEC AND ERROR WITHIN BOUNDS.  COAST IF BELOW FIREFCT, FIRE IF ABOVE

RUFLAW1		CS	RUFRATE		# DECREMENT EDOT BY .1444 RAD/SEC AT PI/4
		ADS	EDOT		#	WHICH IS THE TARGET RATE
		EXTEND
		BZMF	SMALRATE	# BRANCH IF RATE LESS THAN TARGET.
		TC	RUFSETUP	# REVERSE ROTSENSE AND INDICATE MAX JETS.
		CAE	EDOT		# PICK UP DESIRED RATE CHANGE.

RUFLAW12	EXTEND			# COMPUTE TJET
		INDEX	ADRSDIF2	#	= (DESIRED RATE CHANGE)/(2-JET ACCEL.)
		MP	1/ANET1 +2
		AD	-1/8		# IF TJET, SCALED AT 32 SEC, EXCEEDS
		EXTEND			# 	4 SECONDS, SET TJET TO TJMAX.
		BZMF	+2
		TCF	FULLTIME
		EXTEND
		BZF	FULLTIME
		AD	BIT12		# RESTORE COMPUTED TJET TO ACCUMULATOR
		DAS	A
		DAS	A
		DAS	A		# RESCALED TJET AT 4 SECONDS.
		TCF	CHKMINTJ	# RETURN AS FROM FINELAW.

SMALRATE	TC	RUFSETUP +2	# SET NUMBERT AND FIREFCT FOR MAXIMUM JETS
		CCS	ROTSENSE
		CAF	ONE		# MODIFY INDEXER TO POINT TO 1/ANET
		TCF	+2		#	CORRESPONDING TO THE PROPER SENSE.
		CAF	NEGONE
		ADS	ADRSDIF2

		CS	EDOT		# (.144 AT PI/4 - EDOT) = DESIRED RATE CHNG.
		TCF	RUFLAW12

RUFLAW2		TC	RUFSETUP	# REVERSE ROTSENSE AND INDICATE MAX JETS.
		CAF	RUFRATE
		AD	EDOT		# (.144 AT PI/4 + EDOT) = DESIRED RATE CHNG.
		TS	A		# IF OVERFLOW SKIP, FIRE FOR FULL TIME.
		TCF	RUFLAW12	# OTHERWISE, COMPUTE JET TIME.
		TCF	FULLTIME

# Page 1469
RUFLAW3		TC	RUFSETUP	# EXECUTE COMMON RUFLAW SUBROUTINE.
		INDEX	ADRSDIF1
		CS	FIREDB		# CALCULATE DISTANCE FROM SWITCH CURVE
		AD	E		#	1/ANET1*EDOT*EDOT +E - FIREDB = 0
		EXTEND			#		SCALED AT 4 PI RADIANS
		MP	BIT11
		XCH	EDOT
		EXTEND
		SQUARE
		EXTEND
		INDEX	ADRSDIF1
		MP	1/ANET1 +2
		AD	EDOT
		EXTEND
		BZMF	COASTTJ		# COAST IF BELOW IT.
		TCF	FULLTIME	# FIRE FOR FULL PERIOD IF ABOVE IT.

# SUBROUTINE USED IN ALL ENTRIES TO ROUGHLAW.

RUFSETUP	CS	ROTSENSE	# REVERSE ROTSENSE WHEN ENTER HERE.
		TS	ROTSENSE
	+2	CAF	FOUR		# REQUIRE MAXIMUM (2) JETS IN U,V-AXES.
		TS	NUMBERT
		CAF	NEGMAX		# SUGGEST MAXIMUM (4) JETS IN P-AXIS.
		TS	FIREFCT
		TC	Q

# CONSTANTS FOR TJETLAW

		DEC	-16		# AXISDIFF(INDEX) = NUMBER OF REGISTERS
AXISDIFF	DEC	+0		#	BETWEEN STORED 1/ACCS PARAMETERS FOR
		DEC	16		#	THE INDEXED AXIS AND THE U-AXIS.
SENSOR		OCT	14400		# RATIO OF TJET SCALING WITHIN TJETLAW
					#	(4 SEC) TO SCALING FOR T6 (10.24 SEC).
-3DEG		DEC	-.06667		# -3.0 DEGREES SCALED AT 45.
-.0112A8	DEC	-.00141		# -.01125 SEC(2) SCALED AT 8.
.1AT4		DEC	.025		# 0.1 SECOND SCALED AT 4.
.1AT2		DEC	.05		# .1 SEC SCALED AT 2.
.0375AT4	DEC	.00938		# .0375 SEC SCALED AT 4.
-.025AT2	DEC	-.0125		# -.025 SEC SCALED AT 2.
-.025AT4	DEC	-.00625
-.05AT2		DEC	-.025
-.15AT2		DEC	-.075
.00375A8	2DEC	.00375 B-3

-TJMAX		DEC	-.0375		# LARGEST CALCULATED TIME.  .150 SEC AT 4.
TJMIN		DEC	.005		# SMALLEST ALLOWABLE TIME.  .020 SEC AT 4.
-TJMIN		DEC	-.005
RUFRATE		DEC	.1444		# CORRESPONDS TO TARGET RATE OF 6.5 DEG/S.
