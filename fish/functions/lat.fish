function lat
   set file
   if count $LATEX
      set  _lat $LATEX
   else
      set  _lat latex
   end
   echo _lat is $_lat
   for file in $argv
      set CURRENT_FILE (basename "$file" .tex)
      set CURRENT_FILE (basename "$CURRENT_FILE" .)
      $_lat "$CURRENT_FILE.tex" && $_lat "$CURRENT_FILE.tex" && $_lat "$CURRENT_FILE.tex" &&  \
      [ "$_lat" = latex ] && dvips "$CURRENT_FILE.dvi"    # 3 times to get all references right, no dvips for pdflatex, xelatex
   end
end
# EOF

