// regex is just a special case of a finite-state-automaton

// enum not available; use preprocessor instead
#define STATE_START     0x0000
#define STATE_M         0x0080
#define STATE_MU        0x0100
#define STATE_MUL       0x0180
#define STATE_MULP      0x0200
#define STATE_MULPC     0x0280
#define STATE_D         0x0300
#define STATE_DO        0x0380
#define STATE_DON       0x0400
#define STATE_DON_      0x0480
#define STATE_DON_T     0x0500
#define STATE_DON_TP    0x0580
#define STATE_DOP       0x0600

U0 Main() {
    I64 len;
    U8 *data = FileRead("input03.txt", &len);
    Bool enable = TRUE;
    U16 state = STATE_START;
    I64 acc1 = 0, acc2 = 0, p1 = 0, p2 = 0;

    for (I64 i = 0; i < len; i++) {
        switch (state + data[i]) {
        case STATE_M + 'u':
            state = STATE_MU; break;
        case STATE_MU + 'l':
            state = STATE_MUL; break;
        case STATE_MUL + '(':
            acc1 = 0;
            state = STATE_MULP; break;
        case STATE_MULP + '0' ... STATE_MULP + '9':
            acc1 = (acc1 * 10) + (data[i] - '0');
            // no state change
            break;
        case STATE_MULP + ',':
            acc2 = 0;
            state = STATE_MULPC; break;
        case STATE_MULPC + '0' ... STATE_MULPC + '9':
            acc2 = (acc2 * 10) + (data[i] - '0');
            // no state change
            break;
        case STATE_MULPC + ')':
            p1 += (acc1 * acc2);
            p2 += (enable * acc1 * acc2);
            state = STATE_START; break;

        case STATE_D + 'o':
            state = STATE_DO; break;
        case STATE_DO + '(':
            state = STATE_DOP; break;
        case STATE_DOP + ')':
            enable = TRUE;
            state = STATE_START; break;
        case STATE_DO + 'n':
            state = STATE_DON; break;
        case STATE_DON + '\'':
            state = STATE_DON_; break;
        case STATE_DON_ + 't':
            state = STATE_DON_T; break;
        case STATE_DON_T + '(':
            state = STATE_DON_TP; break;
        case STATE_DON_TP + ')':
            enable = FALSE;
            state = STATE_START; break;

        default:
            if (data[i] == 'm') {
                state = STATE_M;
            } else if (data[i] == 'd') {
                state = STATE_D;
            } else {
                state = STATE_START;
            }
        }
    }
    Free(data);
    "%d\n%d\n", p1, p2;
}
