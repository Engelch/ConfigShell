function determineChecksumProg() {
   debug determineChecksumProg.............
   [ ! -z "$_checksum" ] && debug4 _checksum already set && return 
   if [ $(which gosha256 2>/dev/null | wc -l) -gt 0 ] ; then   # gosha256 found
      _checksum=gosha256
   elif [ $(which sha256sum 2>/dev/null | wc -l) -gt 0 ] ; then
      _checksum=sha256sum
   elif [ $(which shasum 2>/dev/null | wc -l) -gt 0 ] ; then
      _checksum="shasum -a 256"
   else
      errorExit 10 No suitable SHA256 digest creation application found.
   fi
   debug4 _checksum $_checksum
}

