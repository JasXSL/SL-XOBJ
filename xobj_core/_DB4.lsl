#ifndef __DB4
#define __DB4
/*
    DB4 creates sequential LSD auto increase int keys and assigns them as chars
    Each table is assigned 1 character as an identifier (referred to as tableChar or ch)
    Each row is assigned 1 character corresponding to its ID

    Limitations:
    - If creating your own tables outside of DB4, use 1 or 3+ character length. 
        DB4 lsd indexes are always two characters long, and span all character combinations.
    - You cannot use an empty table name
    - It does not check for deleted keys. 
        If you delete many many entries from a table, you may want to reindex to speed things up.
		
    Table names:
    (char table)(unicode 9) : Current auto increase index of the table
	(char table)(char row) : A tableChar followed by a row ID converted to a char is a table row.
                            Stores your data. You can put any data here.
    
*/

// NOTE: "char" below is used to represent an integer stored as a single character string.
// NOTE: Plus notation lets you make a list by using a plus, or inputting a single value.
//      A benefit is that the preprocessor does not throw a fit when you use [] in a macro.
//      A drawback is that if you are going to use + for math or string joining in the macro, you must wrap that in parentheses
//      Example: Instead of ["var1", "var2"] you can do "var1" + "var2". And instead of ["var"] you can do "var"
//      

// Have the root script create tables. This is recommended because it prevents race conditions. stdMethod$setShared is run as a callback on table creation.
// note: if a table exists nothing happens, and the callback stdMethod$setShared will still include the table
#define db4$ofs 33	// Added to every table and insert char. Because SL breaks if you use controlchars below 32. tableChar()+u32 is used to maintain index
#define db4$idxChar " " 	// Unicode 32 is used to mark as index val

#define db4$setIndex(table, nrEntries) llLinksetDataWrite(table+db4$idxChar, (str)(nrEntries))
#define db4$getIndex(table) (int)llLinksetDataRead(table+db4$idxChar)
#define db4$get(table, index) llLinksetDataRead(table+llChar(index+db4$ofs))
#define db4$delete(table, index) llLinksetDataDelete(table+llChar(db4$ofs+index))
#define db4$replace(table, index, data) llLinksetDataWrite(table+llChar(db4$ofs+index), (str)(data))
// // Todo: replaced with in future: llLinksetDataDeleteFound("^"+table+".{1}$", "")
#define db4$drop(table) llLinksetDataDeleteFound("^"+table+".{1}$", "") //_4d(table)

// These are faster than above by using a precalculated index char
#define db4$fget(table, idxChar) llLinksetDataRead(table+idxChar)
#define db4$fdelete(table, idxChar) llLinksetDataDelete(table+idxChar)
#define db4$freplace(table, idxChar, data) llLinksetDataWrite(table+idxChar, (str)(data))


#define db4$insert(table, data) _4i(table, (str)(data))
integer _4i( string table, string data ){
	integer n = db4$getIndex(table);
	llLinksetDataWrite(table+llChar(n+db4$ofs), data);
	db4$setIndex(table, n+1);
	return n;
}



// Loop over valid rows
#define db4$each(table, index, dataVar, code) \
    { \
        integer _m = db4$getIndex(table); \
        integer index; \
        for(; index < _m; ++index ){ \
            str dataVar = db4$get(table, index); \
            if( dataVar ){ \
                code \
            } \
        } \
    }


// NOTE: USE THE MACROS ABOVE. NOT THESE.

// Drops a DB4 table
/*
_4d( string t ){
    
	list found; integer i;
	while( (found = llLinksetDataFindKeys("^"+t+".{1}$", 0, 50)) != [] ){ \
		for( i = 0; i < count(found); ++i ) \
			llLinksetDataDelete(l2s(found, i)); \
	}
    
}
*/



dumpLSD(){
	list keys = llLinksetDataListKeys(0,-1);
	integer i;
	for( i = 0; i < count(keys); ++i )
		llOwnerSay(l2s(keys, i)+" >> "+llLinksetDataRead(l2s(keys, i)));
}



// List of index chars starting from 32 db4$0 is actually llChar(db4$ofs)
#define db4$0 "!"
#define db4$1 "\""
#define db4$2 "#"
#define db4$3 "$"
#define db4$4 "%"
#define db4$5 "&"
#define db4$6 "'"
#define db4$7 "("
#define db4$8 ")"
#define db4$9 "*"
#define db4$10 "+"
#define db4$11 ","
#define db4$12 "-"
#define db4$13 "."
#define db4$14 "/"
#define db4$15 "0"
#define db4$16 "1"
#define db4$17 "2"
#define db4$18 "3"
#define db4$19 "4"
#define db4$20 "5"
#define db4$21 "6"
#define db4$22 "7"
#define db4$23 "8"
#define db4$24 "9"
#define db4$25 ":"
#define db4$26 ";"
#define db4$27 "<"
#define db4$28 "="
#define db4$29 ">"
#define db4$30 "?"
#define db4$31 "@"
#define db4$32 "A"
#define db4$33 "B"
#define db4$34 "C"
#define db4$35 "D"
#define db4$36 "E"
#define db4$37 "F"
#define db4$38 "G"
#define db4$39 "H"
#define db4$40 "I"
#define db4$41 "J"
#define db4$42 "K"
#define db4$43 "L"
#define db4$44 "M"
#define db4$45 "N"
#define db4$46 "O"
#define db4$47 "P"
#define db4$48 "Q"
#define db4$49 "R"
#define db4$50 "S"
#define db4$51 "T"
#define db4$52 "U"
#define db4$53 "V"
#define db4$54 "W"
#define db4$55 "X"
#define db4$56 "Y"
#define db4$57 "Z"
#define db4$58 "["
#define db4$59 "\\"
#define db4$60 "]"
#define db4$61 "^"
#define db4$62 "_"
#define db4$63 "`"
#define db4$64 "a"
#define db4$65 "b"
#define db4$66 "c"
#define db4$67 "d"
#define db4$68 "e"
#define db4$69 "f"
#define db4$70 "g"
#define db4$71 "h"
#define db4$72 "i"
#define db4$73 "j"
#define db4$74 "k"
#define db4$75 "l"
#define db4$76 "m"
#define db4$77 "n"
#define db4$78 "o"
#define db4$79 "p"
#define db4$80 "q"
#define db4$81 "r"
#define db4$82 "s"
#define db4$83 "t"
#define db4$84 "u"
#define db4$85 "v"
#define db4$86 "w"
#define db4$87 "x"
#define db4$88 "y"
#define db4$89 "z"
#define db4$90 "{"
#define db4$91 "|"
#define db4$92 "}"
#define db4$93 "~"
#define db4$94 ""
#define db4$95 ""
#define db4$96 ""
#define db4$97 ""
#define db4$98 ""
#define db4$99 ""
#define db4$100 ""
#define db4$101 ""
#define db4$102 ""
#define db4$103 ""
#define db4$104 ""
#define db4$105 ""
#define db4$106 ""
#define db4$107 ""
#define db4$108 ""
#define db4$109 ""
#define db4$110 ""
#define db4$111 ""
#define db4$112 ""
#define db4$113 ""
#define db4$114 ""
#define db4$115 ""
#define db4$116 ""
#define db4$117 ""
#define db4$118 ""
#define db4$119 ""
#define db4$120 ""
#define db4$121 ""
#define db4$122 ""
#define db4$123 ""
#define db4$124 ""
#define db4$125 ""
#define db4$126 ""
#define db4$127 " "
#define db4$128 "¡"
#define db4$129 "¢"
#define db4$130 "£"
#define db4$131 "¤"
#define db4$132 "¥"
#define db4$133 "¦"
#define db4$134 "§"
#define db4$135 "¨"
#define db4$136 "©"
#define db4$137 "ª"
#define db4$138 "«"
#define db4$139 "¬"
#define db4$140 "­"
#define db4$141 "®"
#define db4$142 "¯"
#define db4$143 "°"
#define db4$144 "±"
#define db4$145 "²"
#define db4$146 "³"
#define db4$147 "´"
#define db4$148 "µ"
#define db4$149 "¶"
#define db4$150 "·"
#define db4$151 "¸"
#define db4$152 "¹"
#define db4$153 "º"
#define db4$154 "»"
#define db4$155 "¼"
#define db4$156 "½"
#define db4$157 "¾"
#define db4$158 "¿"
#define db4$159 "À"
#define db4$160 "Á"
#define db4$161 "Â"
#define db4$162 "Ã"
#define db4$163 "Ä"
#define db4$164 "Å"
#define db4$165 "Æ"
#define db4$166 "Ç"
#define db4$167 "È"
#define db4$168 "É"
#define db4$169 "Ê"
#define db4$170 "Ë"
#define db4$171 "Ì"
#define db4$172 "Í"
#define db4$173 "Î"
#define db4$174 "Ï"
#define db4$175 "Ð"
#define db4$176 "Ñ"
#define db4$177 "Ò"
#define db4$178 "Ó"
#define db4$179 "Ô"
#define db4$180 "Õ"
#define db4$181 "Ö"
#define db4$182 "×"
#define db4$183 "Ø"
#define db4$184 "Ù"
#define db4$185 "Ú"
#define db4$186 "Û"
#define db4$187 "Ü"
#define db4$188 "Ý"
#define db4$189 "Þ"
#define db4$190 "ß"
#define db4$191 "à"
#define db4$192 "á"
#define db4$193 "â"
#define db4$194 "ã"
#define db4$195 "ä"
#define db4$196 "å"
#define db4$197 "æ"
#define db4$198 "ç"
#define db4$199 "è"
#define db4$200 "é"
#define db4$201 "ê"
#define db4$202 "ë"
#define db4$203 "ì"
#define db4$204 "í"
#define db4$205 "î"
#define db4$206 "ï"
#define db4$207 "ð"
#define db4$208 "ñ"
#define db4$209 "ò"
#define db4$210 "ó"
#define db4$211 "ô"
#define db4$212 "õ"
#define db4$213 "ö"
#define db4$214 "÷"
#define db4$215 "ø"
#define db4$216 "ù"
#define db4$217 "ú"
#define db4$218 "û"
#define db4$219 "ü"
#define db4$220 "ý"
#define db4$221 "þ"
#define db4$222 "ÿ"



#endif
