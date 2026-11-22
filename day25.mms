InputL  IS 500
BufLen  IS 8
InFile  IS 3

keyAddr GREG
        LOC Data_Segment
        % Each item in the input is stored as one tetrabyte (32 bits).
        % The first and last lines are stored as a bits, and the last
        % line is not stored at all.
        % The remaining characters are stored bit-wise.
        % For example, here is how this one input item is stored:
        % ##### (0b1)
        % ###.# (0b11101)
        % #.#.# (0b10101)
        % #.#.# (0b10101)
        % ..#.# (0b00101)
        % ..#.. (0b00100)
        % ..... (0b0)
        % for a total of 27 bits.
        % (In principle, you could also store this as a signed 5-digit
        % number in base 6 -- 15552 different values -- which would fit
        % in a 16-bit value. But this would require reading the input
        % "vertically", and encoding/decoding would be a pain!)

        GREG @
        % Puzzle input
PuzzleI TETRA 0
        LOC PuzzleI+(InputL*4)
        GREG @
PuzzleE BYTE 0

        LOC #1000
        GREG @
        % Static(-ish) Data
InpAddr OCTA PuzzleI
FileDat OCTA FileNam,TextRead
FileNam BYTE "input25.txt",0

TextBuf BYTE 0
        LOC TextBuf+BufLen
ReadArg OCTA TextBuf,BufLen

        LOC #100

nKeys   IS $0
k1Addr  IS $1
k2Addr  IS $2
key1    IS $3
key2    IS $4
soln    IS $5
keyEnd  IS $6
Main    GETA $255,FileDat
        TRAP 0,Fopen,InFile
        LDA keyAddr,PuzzleI
        SET nKeys,InputL
RLoop   PUSHJ 1,ReadKey
        SUB nKeys,nKeys,1
        ADD keyAddr,keyAddr,4
        BNZ nKeys,RLoop
        % All 500 keys have been read
        TRAP 0,Fclose,InFile

        LDA keyEnd,PuzzleE
        SET soln,0
        LDA k1Addr,PuzzleI
        SUBU k1Addr,k1Addr,4

KLoop   ADDU k1Addr,k1Addr,4
        ADDU k2Addr,k1Addr,4
        CMP $0,k1Addr,keyEnd
        BNN $0,KDone
        LDT key1,k1Addr

KLooop  CMP $0,k2Addr,keyEnd
        BNN $0,KLoop
        LDT key2,k2Addr
        AND key2,key1,key2
        BNZ key2,KNext
        ADDU soln,soln,1
KNext   ADDU k2Addr,k2Addr,4
        JMP KLooop

        % == Output Routine ==
        % digit 0
KDone   DIV soln,soln,10
        GET $0,rR
        ADDU $0,$0,#30 % '0'
        STB $0,TextBuf+3
        % digit 1
        DIV soln,soln,10
        GET $0,rR
        ADDU $0,$0,#30 % '0'
        STB $0,TextBuf+2
        % digit 2
        DIV soln,soln,10
        GET $0,rR
        ADDU $0,$0,#30 % '0'
        STB $0,TextBuf+1
        % digit 3
        DIV soln,soln,10
        GET $0,rR
        ADDU $0,$0,#30 % '0'
        STB $0,TextBuf+0
        % Newline
        SET $0,#0a
        STB $0,TextBuf+4
        % Terminating null
        SET $0,#0
        STB $0,TextBuf+5
        GETA $255,TextBuf
        TRAP 0,Fputs,StdOut
        TRAP 0,Halt,0

        % == Input Routine ==
        % Note: #2E is '.' and #23 is '#'
placVal IS $0 % place value to add to accumulator
bufAddr IS $1 % address of text buffer
bufByte IS $2 % byte from text buffer
theKey  IS $3 % accumulator
nLines  IS $4 % remaining lines left to read
charRem IS $5 % characters remaining to read this line
ReadKey SET placVal,1
        SET theKey,0
        SET nLines,5
        % == First line - only store one bit ==
        GETA $255,ReadArg
        TRAP 0,Fgets,InFile
        LDA bufAddr,TextBuf
        LDBU bufByte,bufAddr,0
        SUB bufByte,bufByte,#2E
        % If this is not zero, we've read a '#'
        BZ bufByte,RLine
        ADDU theKey,theKey,placVal

        % == Read line ==
RLine   GETA $255,ReadArg
        TRAP 0,Fgets,InFile
        SET charRem,5
        LDA bufAddr,TextBuf
        % == Read byte within line ==
RChar   SL placVal,placVal,1
        LDBU bufByte,bufAddr,0
        ADDU bufAddr,bufAddr,1
        SUB bufByte,bufByte,#2E
        % If this is not zero, we've read a '#'
        BZ bufByte,SkipAdd
        ADDU theKey,theKey,placVal
SkipAdd SUB charRem,charRem,1
        BNZ charRem,RChar
        SUB nLines,nLines,1
        BNZ nLines,RLine

        % == Read last line - only store one bit ==
        GETA $255,ReadArg
        TRAP 0,Fgets,InFile
        LDA bufAddr,TextBuf
        LDBU bufByte,bufAddr,0
        SUB bufByte,bufByte,#2E
        % If this is not zero, we've read a '#'
        BZ bufByte,RDone
        SL placVal,placVal,1
        ADDU theKey,theKey,placVal

RDone   STT theKey,keyAddr
        % Read one more blank line
        GETA $255,ReadArg
        TRAP 0,Fgets,InFile
        POP 0,0
