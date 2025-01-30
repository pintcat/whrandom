######################################################################################################################
# whrandom v2.14 - POSIX compliant random number generator using old or new improved Wichmann-Hill method from 2006. #
# Handshake:                                                                                                         #
# $WH_MAX contains the maximum value for the random number. If set to 0 no limiter will be applied (default: 0).     #
# $WH_LOOP contains the number of random numbers to be generated. Set it to "U" for an unlimited random number       #
#  generation (default: 1).                                                                                          #
# $WH_PREC contains the precision level for the calculation. The lower the level the less percise and thus less      #
#  random the result will be. Must be between 1 and 9 (default: 9).                                                  #
# $WH_DEL contains the delimiter used to separate multiple values (default: \n (new line)).                          #
# $WH_ALGO tells which algorithm will be used - WH_OLD or WH_NEW (default: WH_NEW).                                  #
# Usage:                                                                                                             #
# Simply call WH_RANDOM() to generate one or more random numbers. These numbers will be written to stdout.           #
# The old Wichmann-Hill algorrithm requires 3, the new one 4 seeds each between 1 and 30000. By default, whrandom    #
# automatically creates 4 unique seeds using the millisecond counter of the system clock. Alternatively, you can     #
# call WH_RANDOM() with up to 4 integers. They will be checked and exchanged with automatically generated ones if    #
# they don't fit the needs. Beware: If you use 4 fixed seeds whrandom will always create an identical chain of       #
# random numbers as long as you use the same seeds.                                                                  #
######################################################################################################################

WH_MAX=0
WH_LOOP=1
WH_PREC=9
WH_DEL="\n"
WH_ALGO=WH_NEW

# WH_CHECK() - checks if a value is given, if this value is a number and if it's between 1 and 30000. If so it
#  returns that very number and if not it generates a suitable one using the system clock's millisecond counter.
# IN:  $1 should contain an integer between 1 and 30000.
# OUT: Prints the fitting number to stdout.

WH_CHECK(){
	if [ -n "${1##*[!0-9]*}" ] && [ $1 -gt 0 ] && [ $1 -le 30000 ]; then
		printf $1
	else
		WH_TMP=$(date +%5N)
		WH_TMP=$((${WH_TMP#${WH_TMP%%[1-9]*}}+1))    # remove leading zeros & add 1 to prevent 0 as value
		[ $WH_TMP -gt 30000 ] && WH_TMP=$((WH_TMP/4))
		printf $WH_TMP
	fi
}

# WH_OLD() - generates a random number using the older 16bit integer based algorithm.
# IN:  $WH_S1, $WH_S2 & $WH_S3 contain the values (seeds) needed by the algorithm for computation.
#      $WH_F contains a decimal factor to produce larger, more precise random integers.
# OUT: $WH_RND contains the random number to be handed over to the core function for further operations.

WH_OLD(){
	[ $((WH_S1=171*($WH_S1%177)-2*($WH_S1/177))) -lt 0 ] && WH_S1=$(($WH_S1+30269))
	[ $((WH_S2=172*($WH_S2%176)-35*($WH_S2/176))) -lt 0 ] && WH_S2=$(($WH_S2+30307))
	[ $((WH_S3=170*($WH_S3%178)-63*($WH_S3/178))) -lt 0 ] && WH_S3=$(($WH_S3+30323))
	WH_RND=$((($WH_S1*$WH_F/30269)+($WH_S2*$WH_F/30307)+($WH_S3*$WH_F/30323)))
}

# WH_NEW() - generates a random number using the newer 32bit integer based algorithm.
# IN:  $WH_S1, $WH_S2, $WH_S3 & $WH_S4 contain the values (seeds) needed by the algorithm for computation.
#      $WH_F contains a decimal factor to produce larger, more precise random integers.
# OUT: $WH_RND contains the random number to be handed over to the core function for further operations.

WH_NEW(){
	[ $((WH_S1=11600*($WH_S1%185127)-10379*($WH_S1/185127))) -lt 0 ] && WH_S1=$(($WH_S1+2147483579))
	[ $((WH_S2=47003*($WH_S2%45688)-10479*($WH_S2/45688))) -lt 0 ] && WH_S2=$(($WH_S2+2147483543))
	[ $((WH_S3=23000*($WH_S3%93368)-19423*($WH_S3/93368))) -lt 0 ] && WH_S3=$(($WH_S3+2147483423))
	[ $((WH_S4=33000*($WH_S4%65075)-8123*($WH_S4/65075))) -lt 0 ] && WH_S4=$(($WH_S4+2147483123))
	WH_RND=$((($WH_S1*$WH_F/2147483579)+($WH_S2*$WH_F/2147483543)+($WH_S3*$WH_F/2147483423)+($WH_S4*$WH_F/2147483123)))
}

# WH_RANDOM() - core function: prepares seeds and generates the output.
# IN:  $1, $2, $3 and $4 can contain integers between 1 and 30000 to be used as seeds. These values will be checked and -
#       if not suitable - replaced with auto generated ones.
#      $WH_PREC is the precision level. Each seed is multiplied with 10^$WH_PREC to receive a larger, more accurate value.
#      $WH_LOOP tells how many numbers will be generated. "U" will generate a never ending chain of random numbers.
#      $WH_RND contains the random number which was handed over by the algorithm for further operations.
#      $WH_MAX contains the maximum value which will not be exceeded by the random number. 0 leaves the result unaltered.
#      $WH_DEL contains the delimiter which is placed after each value.
# OUT: $WH_F contains a decimal factor used by the algorithm to produce larger, more precise random integers.
#      $WH_SEEDS contains the original seeds used for the 1st iteration.
#      $WH_RND contains the current random number
#      Also prints the random numbers with delimiter appended to stdout.

WH_RANDOM(){
	WH_F=10
	WH_TMP=$WH_PREC
	while [ $((WH_TMP=$WH_TMP-1)) -gt 0 ]; do
		[ $WH_F -lt 1000000000 ] && WH_F=$(($WH_F*10)) || WH_TMP=1
	done
	WH_S1=$(WH_CHECK $1)
	WH_S2=$(WH_CHECK $2)
	WH_S3=$(WH_CHECK $3)
	WH_S4=$(WH_CHECK $4)
	WH_SEEDS="$WH_S1 $WH_S2 $WH_S3 $WH_S4"
	while [ $WH_LOOP = U ] || [ $((WH_TMP=$WH_TMP+1)) -le $WH_LOOP ]; do
		$WH_ALGO
		[ $WH_MAX -gt 0 ] && printf $(((($WH_RND%$WH_F*$WH_MAX)+$WH_F*10/18)/$WH_F))"$WH_DEL" || printf $WH_RND"$WH_DEL"
		# former rounding routine using parameter expansion - faster, but less accurate & less secure (broken in latest bash)
		#WH_RND=$(($WH_RND%$WH_F*$WH_MAX))
		#[ $WH_MAX -gt 0 ] && printf "%.0f$WH_DEL" "${WH_RND}e-$WH_PREC" || printf $WH_RND"$WH_DEL"
	done
}
