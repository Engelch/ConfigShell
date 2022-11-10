# example to change the cd function without ending up an in endless loop.
#
function cd() {
 echo hup
 command cd $*
}
