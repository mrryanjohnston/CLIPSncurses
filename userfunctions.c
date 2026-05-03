   /*******************************************************/
   /*      "C" Language Integrated Production System      */
   /*                                                     */
   /*            CLIPS Version 6.40  07/30/16             */
   /*                                                     */
   /*                USER FUNCTIONS MODULE                */
   /*******************************************************/

/*************************************************************/
/* Purpose:                                                  */
/*                                                           */
/* Principal Programmer(s):                                  */
/*      Gary D. Riley                                        */
/*                                                           */
/* Contributing Programmer(s):                               */
/*                                                           */
/* Revision History:                                         */
/*                                                           */
/*      6.24: Created file to seperate UserFunctions and     */
/*            EnvUserFunctions from main.c.                  */
/*                                                           */
/*      6.30: Removed conditional code for unsupported       */
/*            compilers/operating systems (IBM_MCW,          */
/*            MAC_MCW, and IBM_TBC).                         */
/*                                                           */
/*            Removed use of void pointers for specific      */
/*            data structures.                               */
/*                                                           */
/*************************************************************/

/***************************************************************************/
/*                                                                         */
/* Permission is hereby granted, free of charge, to any person obtaining   */
/* a copy of this software and associated documentation files (the         */
/* "Software"), to deal in the Software without restriction, including     */
/* without limitation the rights to use, copy, modify, merge, publish,     */
/* distribute, and/or sell copies of the Software, and to permit persons   */
/* to whom the Software is furnished to do so.                             */
/*                                                                         */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS */
/* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF              */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT   */
/* OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY  */
/* CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES */
/* WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN   */
/* ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF */
/* OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.          */
/*                                                                         */
/***************************************************************************/

#include "clips.h"
#include <ncurses.h>

void UserFunctions(Environment *);

// Normally the first function call in an ncurses program.
// Used to initialize the library
// and set up the terminal for screen manipulation.
void NcursesinitscrFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->externalAddressValue = CreateCExternalAddress(theEnv, (void*)initscr());
}

#define HANDLE_OK_OR_ERR(UDF_FUNCTION_NAME, RESULT) \
switch(RESULT) \
{ \
	case OK: \
		returnValue->lexemeValue = CreateSymbol(theEnv, "OK"); \
		break; \
	case ERR: \
		returnValue->lexemeValue = CreateSymbol(theEnv, "ERR"); \
		break; \
	default: \
		WriteString(theEnv, STDERR, "ncurses-" #UDF_FUNCTION_NAME ": Received something unexpected from " #UDF_FUNCTION_NAME "\n"); \
		returnValue->lexemeValue = CreateSymbol(theEnv, "FALSE"); \
		break; \
}

#define HANDLE_OK_OR_ERR_FUNCTION(FUNCTION_NAME) \
void Ncurses##FUNCTION_NAME##Function(Environment *theEnv, UDFContext *context, UDFValue *returnValue) \
{ \
	HANDLE_OK_OR_ERR(FUNCTION_NAME, FUNCTION_NAME()); \
}

HANDLE_OK_OR_ERR_FUNCTION(echo)
HANDLE_OK_OR_ERR_FUNCTION(noecho)
HANDLE_OK_OR_ERR_FUNCTION(cbreak)
HANDLE_OK_OR_ERR_FUNCTION(nocbreak)
HANDLE_OK_OR_ERR_FUNCTION(clear)
HANDLE_OK_OR_ERR_FUNCTION(refresh)
HANDLE_OK_OR_ERR_FUNCTION(endwin)
HANDLE_OK_OR_ERR_FUNCTION(doupdate)

void Ncursesstart_colorFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	HANDLE_OK_OR_ERR("start_color", start_color());
}

#define SET_OPTION(FUNCTION_NAME) \
void Ncurses##FUNCTION_NAME##Function(Environment *theEnv, UDFContext *context, UDFValue *returnValue) \
{ \
	UDFValue theArg; \
	WINDOW *window = stdscr; \
	bool bf = TRUE; \
	\
	if (UDFHasNextArgument(context)) \
	{ \
		UDFNextArgument(context,EXTERNAL_ADDRESS_BIT | SYMBOL_BIT,&theArg); \
		if (theArg.header->type == SYMBOL_TYPE) \
	        { \
			if (0 != strcmp("stdscr", theArg.lexemeValue->contents)) \
			{ \
				WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": first arg must be a Window pointer or stdscr\n"); \
				returnValue->lexemeValue = FalseSymbol(theEnv); \
				return; \
			} \
		} \
		else \
		if (theArg.header->type != EXTERNAL_ADDRESS_TYPE) \
		{ \
			WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": first arg must be a Window pointer or stdscr\n"); \
			returnValue->lexemeValue = FalseSymbol(theEnv); \
			return; \
		} \
		else \
		{ \
			window = theArg.externalAddressValue->contents; \
		} \
	} \
	\
	if (UDFHasNextArgument(context)) \
	{ \
		UDFNextArgument(context, SYMBOL_BIT, &theArg); \
		if (theArg.header->type != SYMBOL_TYPE || (theArg.lexemeValue != TrueSymbol(theEnv) && theArg.lexemeValue != FalseSymbol(theEnv))) \
		{ \
			WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": second arg must be TRUE or FALSE\n"); \
			returnValue->lexemeValue = FalseSymbol(theEnv); \
			return; \
		} \
		if (theArg.lexemeValue == FalseSymbol(theEnv)) \
		{ \
			bf = FALSE; \
		} \
	} \
	\
	HANDLE_OK_OR_ERR(FUNCTION_NAME, FUNCTION_NAME(window, bf)); \
}

SET_OPTION(keypad)
SET_OPTION(leaveok)

#define BUF_SIZE 4096
void NcursesmvprintwFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{

	UDFValue theArg;
	int x, y;

	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "ncurses-mvprintw: first arg must be integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	x = theArg.integerValue->contents;

	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "ncurses-mvprintw: second arg must be integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	y = theArg.integerValue->contents;

	UDFNextArgument(context, STRING_BIT, &theArg);
	if (theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, "ncurses-mvprintw: third arg must be string\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	HANDLE_OK_OR_ERR(mvprintw, mvprintw(y, x, "%s", theArg.lexemeValue->contents));
}

const char *KeyToStr(int key)
{
	static char buf[32];
	if (key >= 32 && key <= 126)
	{
		snprintf(buf, sizeof(buf), "%c", key);
		return buf;
	}
	if (key >= KEY_F0 && key <= KEY_F(KEY_MAX))
	{
		snprintf(buf, sizeof(buf), "KEY_F(%d)", key - KEY_F0);
		return buf;
	}
	switch (key)
	{
		case KEY_CODE_YES:
			return "KEY_CODE_YES";
		case KEY_MIN:
			return "KEY_MIN";
		//case KEY_BREAK:
		//	return "KEY_BREAK";
		case KEY_SRESET:
			return "KEY_SRESET";
		case KEY_RESET:
			return "KEY_RESET";
		case KEY_DOWN:
			return "KEY_DOWN";
		case KEY_UP:
			return "KEY_UP";
		case KEY_LEFT:
			return "KEY_LEFT";
		case KEY_RIGHT:
			return "KEY_RIGHT";
		case KEY_HOME:
			return "KEY_HOME";
		case KEY_BACKSPACE:
			return "KEY_BACKSPACE";
		case KEY_DL:
			return "KEY_DL";
		case KEY_IL:
			return "KEY_IL";
		case KEY_DC:
			return "KEY_DC";
		case KEY_IC:
			return "KEY_IC";
		case KEY_EIC:
			return "KEY_EIC";
		case KEY_CLEAR:
			return "KEY_CLEAR";
		case KEY_EOS:
			return "KEY_EOS";
		case KEY_EOL:
			return "KEY_EOL";
		case KEY_SF:
			return "KEY_SF";
		case KEY_SR:
			return "KEY_SR";
		case KEY_NPAGE:
			return "KEY_NPAGE";
		case KEY_PPAGE:
			return "KEY_PPAGE";
		case KEY_STAB:
			return "KEY_STAB";
		case KEY_CTAB:
			return "KEY_CTAB";
		case KEY_CATAB:
			return "KEY_CATAB";
		case KEY_ENTER:
			return "KEY_ENTER";
		case KEY_PRINT:
			return "KEY_PRINT";
		case KEY_LL:
			return "KEY_LL";
		case KEY_A1:
			return "KEY_A1";
		case KEY_A3:
			return "KEY_A3";
		case KEY_B2:
			return "KEY_B2";
		case KEY_C1:
			return "KEY_C1";
		case KEY_C3:
			return "KEY_C3";
		case KEY_BTAB:
			return "KEY_BTAB";
		case KEY_BEG:
			return "KEY_BEG";
		case KEY_CANCEL:
			return "KEY_CANCEL";
		case KEY_CLOSE:
			return "KEY_CLOSE";
		case KEY_COMMAND:
			return "KEY_COMMAND";
		case KEY_COPY:
			return "KEY_COPY";
		case KEY_CREATE:
			return "KEY_CREATE";
		case KEY_END:
			return "KEY_END";
		case KEY_EXIT:
			return "KEY_EXIT";
		case KEY_FIND:
			return "KEY_FIND";
		case KEY_HELP:
			return "KEY_HELP";
		case KEY_MARK:
			return "KEY_MARK";
		case KEY_MESSAGE:
			return "KEY_MESSAGE";
		case KEY_MOVE:
			return "KEY_MOVE";
		case KEY_NEXT:
			return "KEY_NEXT";
		case KEY_OPEN:
			return "KEY_OPEN";
		case KEY_OPTIONS:
			return "KEY_OPTIONS";
		case KEY_PREVIOUS:
			return "KEY_PREVIOUS";
		case KEY_REDO:
			return "KEY_REDO";
		case KEY_REFERENCE:
			return "KEY_REFERENCE";
		case KEY_REFRESH:
			return "KEY_REFRESH";
		case KEY_REPLACE:
			return "KEY_REPLACE";
		case KEY_RESTART:
			return "KEY_RESTART";
		case KEY_RESUME:
			return "KEY_RESUME";
		case KEY_SAVE:
			return "KEY_SAVE";
		case KEY_SBEG:
			return "KEY_SBEG";
		case KEY_SCANCEL:
			return "KEY_SCANCEL";
		case KEY_SCOMMAND:
			return "KEY_SCOMMAND";
		case KEY_SCOPY:
			return "KEY_SCOPY";
		case KEY_SCREATE:
			return "KEY_SCREATE";
		case KEY_SDC:
			return "KEY_SDC";
		case KEY_SDL:
			return "KEY_SDL";
		case KEY_SELECT:
			return "KEY_SELECT";
		case KEY_SEND:
			return "KEY_SEND";
		case KEY_SEOL:
			return "KEY_SEOL";
		case KEY_SEXIT:
			return "KEY_SEXIT";
		case KEY_SFIND:
			return "KEY_SFIND";
		case KEY_SHELP:
			return "KEY_SHELP";
		case KEY_SHOME:
			return "KEY_SHOME";
		case KEY_SIC:
			return "KEY_SIC";
		case KEY_SLEFT:
			return "KEY_SLEFT";
		case KEY_SMESSAGE:
			return "KEY_SMESSAGE";
		case KEY_SMOVE:
			return "KEY_SMOVE";
		case KEY_SNEXT:
			return "KEY_SNEXT";
		case KEY_SOPTIONS:
			return "KEY_SOPTIONS";
		case KEY_SPREVIOUS:
			return "KEY_SPREVIOUS";
		case KEY_SPRINT:
			return "KEY_SPRINT";
		case KEY_SREDO:
			return "KEY_SREDO";
		case KEY_SREPLACE:
			return "KEY_SREPLACE";
		case KEY_SRIGHT:
			return "KEY_SRIGHT";
		case KEY_SRSUME:
			return "KEY_SRSUME";
		case KEY_SSAVE:
			return "KEY_SSAVE";
		case KEY_SSUSPEND:
			return "KEY_SSUSPEND";
		case KEY_SUNDO:
			return "KEY_SUNDO";
		case KEY_SUSPEND:
			return "KEY_SUSPEND";
		case KEY_UNDO:
			return "KEY_UNDO";
		case KEY_MOUSE:
			return "KEY_MOUSE";
#if NCURSES_SIGWINCH
		case KEY_RESIZE:
			return "KEY_RESIZE";
#endif
		case KEY_MAX:
			return "KEY_MAX";
	}
	return NULL;
}

chtype StrToACS(const char *str)
{
	if (0 == strcmp("ACS_ULCORNER", str))
	{
		return ACS_ULCORNER;
	}
	else
	if (0 == strcmp("ACS_LLCORNER", str))
	{
		return ACS_LLCORNER;
	}
	else
	if (0 == strcmp("ACS_URCORNER", str))
	{
		return ACS_URCORNER;
	}
	else
	if (0 == strcmp("ACS_LRCORNER", str))
	{
		return ACS_LRCORNER;
	}
	else
	if (0 == strcmp("ACS_LTEE", str))
	{
		return ACS_LTEE;
	}
	else
	if (0 == strcmp("ACS_RTEE", str))
	{
		return ACS_RTEE;
	}
	else
	if (0 == strcmp("ACS_BTEE", str))
	{
		return ACS_BTEE;
	}
	else
	if (0 == strcmp("ACS_TTEE", str))
	{
		return ACS_TTEE;
	}
	else
	if (0 == strcmp("ACS_HLINE", str))
	{
		return ACS_HLINE;
	}
	else
	if (0 == strcmp("ACS_VLINE", str))
	{
		return ACS_VLINE;
	}
	else
	if (0 == strcmp("ACS_PLUS", str))
	{
		return ACS_PLUS;
	}
	else
	if (0 == strcmp("ACS_S1", str))
	{
		return ACS_S1;
	}
	else
	if (0 == strcmp("ACS_S9", str))
	{
		return ACS_S9;
	}
	else
	if (0 == strcmp("ACS_DIAMOND", str))
	{
		return ACS_DIAMOND;
	}
	else
	if (0 == strcmp("ACS_CKBOARD", str))
	{
		return ACS_CKBOARD;
	}
	else
	if (0 == strcmp("ACS_DEGREE", str))
	{
		return ACS_DEGREE;
	}
	else
	if (0 == strcmp("ACS_PLMINUS", str))
	{
		return ACS_PLMINUS;
	}
	else
	if (0 == strcmp("ACS_BULLET", str))
	{
		return ACS_BULLET;
	}
	else
	/* Teletype 5410v1 symbols begin here */
	if (0 == strcmp("ACS_LARROW", str))
	{
		return ACS_LARROW;
	}
	else
	if (0 == strcmp("ACS_RARROW", str))
	{
		return ACS_RARROW;
	}
	else
	if (0 == strcmp("ACS_DARROW", str))
	{
		return ACS_DARROW;
	}
	else
	if (0 == strcmp("ACS_UARROW", str))
	{
		return ACS_UARROW;
	}
	else
	if (0 == strcmp("ACS_BOARD", str))
	{
		return ACS_BOARD;
	}
	else
	if (0 == strcmp("ACS_LANTERN", str))
	{
		return ACS_LANTERN;
	}
	else
	if (0 == strcmp("ACS_BLOCK", str))
	{
		return ACS_BLOCK;
	}
	else
	/*
	* These aren't documented, but a lot of System Vs have them anyway
	* (you can spot pprryyzz{{||}} in a lot of AT&T terminfo strings).
	* The ACS_names may not match AT&T's, our source didn't know them.
	*/
	if (0 == strcmp("ACS_S3", str))
	{
		return ACS_S3;
	}
	else
	if (0 == strcmp("ACS_S7", str))
	{
		return ACS_S7;
	}
	else
	if (0 == strcmp("ACS_LEQUAL", str))
	{
		return ACS_LEQUAL;
	}
	else
	if (0 == strcmp("ACS_GEQUAL", str))
	{
		return ACS_GEQUAL;
	}
	else
	if (0 == strcmp("ACS_PI", str))
	{
		return ACS_PI;
	}
	else
	if (0 == strcmp("ACS_NEQUAL", str))
	{
		return ACS_NEQUAL;
	}
	else
	if (0 == strcmp("ACS_STERLING", str))
	{
		return ACS_STERLING;
	}
	else

	/*
	* Line drawing ACS names are of the form ACS_trbl, where t is the top, r
	* is the right, b is the bottom, and l is the left.  t, r, b, and l might
	* be B (blank), S (single), D (double), or T (thick).  The subset defined
	* here only uses B and S.
	*/
	if (0 == strcmp("ACS_BSSB", str))
	{
		return ACS_BSSB;
	}
	else
	if (0 == strcmp("ACS_SSBB", str))
	{
		return ACS_SSBB;
	}
	else
	if (0 == strcmp("ACS_BBSS", str))
	{
		return ACS_BBSS;
	}
	else
	if (0 == strcmp("ACS_SBBS", str))
	{
		return ACS_SBBS;
	}
	else
	if (0 == strcmp("ACS_SBSS", str))
	{
		return ACS_SBSS;
	}
	else
	if (0 == strcmp("ACS_SSSB", str))
	{
		return ACS_SSSB;
	}
	else
	if (0 == strcmp("ACS_SSBS", str))
	{
		return ACS_SSBS;
	}
	else
	if (0 == strcmp("ACS_BSSS", str))
	{
		return ACS_BSSS;
	}
	else
	if (0 == strcmp("ACS_BSBS", str))
	{
		return ACS_BSBS;
	}
	else
	if (0 == strcmp("ACS_SBSB", str))
	{
		return ACS_SBSB;
	}
	else
	if (0 == strcmp("ACS_SSSS", str))
	{
		return ACS_SSSS;
	}
	else
	{
		return (chtype) ERR;
	}
}

int StrToAttr(const char *str)
{
	if (0 == strcmp(str, "A_NORMAL"))
	{
		return A_NORMAL;
	}
	else
	if (0 == strcmp(str, "A_STANDOUT"))
	{
		return A_STANDOUT;
	}
	else
	if (0 == strcmp(str, "A_UNDERLINE"))
	{
		return A_UNDERLINE;
	}
	else
	if (0 == strcmp(str, "A_REVERSE"))
	{
		return A_REVERSE;
	}
	else
	if (0 == strcmp(str, "A_BLINK"))
	{
		return A_BLINK;
	}
	else
	if (0 == strcmp(str, "A_DIM"))
	{
		return A_DIM;
	}
	else
	if (0 == strcmp(str, "A_BOLD"))
	{
		return A_BOLD;
	}
	else
	if (0 == strcmp(str, "A_PROTECT"))
	{
		return A_PROTECT;
	}
	else
	if (0 == strcmp(str, "A_INVIS"))
	{
	return A_INVIS;
	}
	else
	if (0 == strcmp(str, "A_ALTCHARSET"))
	{
		return A_ALTCHARSET;
	}
	else
	if (0 == strcmp(str, "A_ITALIC"))
	{
		return A_ITALIC;
	}
	else
	if (0 == strcmp(str, "A_ATTRIBUTES"))
	{
		return A_ATTRIBUTES;
	}
	else
	if (0 == strcmp(str, "A_CHARTEXT"))
	{
		return A_CHARTEXT;
	}
	else
	if (0 == strcmp(str, "A_COLOR"))
	{
		return A_COLOR;
	}
	else
	{
		return -1;
	}
}

int StrToAdditionalAttr(const char *str)
{
	if (0 == strcmp(str, "WA_HORIZONTAL"))
	{
		return WA_HORIZONTAL;
	}
	else
	if (0 == strcmp(str, "WA_LEFT"))
	{
		return WA_LEFT;
	}
	else
	if (0 == strcmp(str, "WA_LOW"))
	{
		return WA_LOW;
	}
	else
	if (0 == strcmp(str, "WA_RIGHT"))
	{
		return WA_RIGHT;
	}
	else
	if (0 == strcmp(str, "WA_TOP"))
	{
		return WA_TOP;
	}
	else
	if (0 == strcmp(str, "WA_VERTICAL"))
	{
		return WA_VERTICAL;
	}
	else
	{
		return -1;
	}
}

void NcursesgetchFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	int ch = getch();
	returnValue->integerValue = CreateInteger(theEnv, ch);
}

void NcurseskeyToStrFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "ncurses-key-to-str: Argument must be an integer");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	const char *out = KeyToStr(theArg.integerValue->contents);
	if (NULL == out)
	{
		returnValue->integerValue = CreateInteger(theEnv, theArg.integerValue->contents);
	}
	else
	{
		returnValue->lexemeValue = CreateSymbol(theEnv, out);
	}
}

void NcursescurssetFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	int previous;
	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "ncurses-curs-set: first arg must be integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	previous = curs_set(theArg.integerValue->contents);
	if (ERR == previous)
	{
		WriteString(theEnv, STDERR, "ncurses-curs-set: curs_set errored when passing it ");
		WriteInteger(theEnv, STDERR, theArg.integerValue->contents);
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
	}
	else
	{
		returnValue->integerValue = CreateInteger(theEnv, previous);
	}
}

#define PARSE_CHTYPE_ARG(FUNCTION_NAME, VARIABLE_NAME, TH)\
UDFNextArgument(context,INTEGER_BIT|MULTIFIELD_BIT|LEXEME_BITS,&theArg); \
chtype VARIABLE_NAME = 0; \
if (theArg.header->type == INTEGER_TYPE) \
{ \
	VARIABLE_NAME = (chtype) theArg.integerValue->contents; \
} \
else \
if (theArg.header->type == MULTIFIELD_TYPE) \
{ \
	chtype chpart = 0, attributes = 0; \
	if (theArg.multifieldValue->length > 0) \
	{ \
		if (theArg.multifieldValue->contents[0].header->type == INTEGER_TYPE) \
		{ \
			chpart = (chtype) theArg.multifieldValue->contents[0].integerValue->contents; \
		} \
		else \
		if (theArg.multifieldValue->contents[0].header->type == SYMBOL_TYPE || theArg.multifieldValue->contents[0].header->type == STRING_TYPE) \
		{ \
			if (theArg.multifieldValue->contents[0].lexemeValue->contents[0] != '\0' && theArg.multifieldValue->contents[0].lexemeValue->contents[1] == '\0') \
			{ \
				chpart = (unsigned char) theArg.multifieldValue->contents[0].lexemeValue->contents[0]; \
			} \
			else \
			if (ERR == (chpart = StrToACS(theArg.multifieldValue->contents[0].lexemeValue->contents))) \
			{ \
				WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": " #TH " arg must be a chtype\n"); \
				returnValue->lexemeValue = FalseSymbol(theEnv); \
				return; \
			} \
		} \
		else \
		{ \
			WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": " #TH " arg must be a chtype\n"); \
			returnValue->lexemeValue = FalseSymbol(theEnv); \
			return; \
		} \
	} \
	if (theArg.multifieldValue->length > 1) \
	{ \
		if (theArg.multifieldValue->contents[1].header->type == INTEGER_TYPE) \
		{ \
			attributes = (chtype) theArg.multifieldValue->contents[1].integerValue->contents; \
		} \
		else \
		{ \
			WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": " #TH " arg must be a chtype\n"); \
			returnValue->lexemeValue = FalseSymbol(theEnv); \
			return; \
		} \
	} \
	VARIABLE_NAME =  chpart | attributes; \
	if (theArg.multifieldValue->length > 2) \
	{ \
		if (theArg.multifieldValue->contents[2].header->type == INTEGER_TYPE) \
		{ \
			VARIABLE_NAME |= COLOR_PAIR(theArg.multifieldValue->contents[2].integerValue->contents); \
		} \
		else \
		{ \
			WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": " #TH " arg must be a chtype\n"); \
			returnValue->lexemeValue = FalseSymbol(theEnv); \
			return; \
		} \
	} \
} \
else \
if (theArg.header->type == SYMBOL_TYPE) \
{ \
	if (theArg.lexemeValue->contents[0] != '\0' && theArg.lexemeValue->contents[1] == '\0') \
	{ \
		VARIABLE_NAME = (unsigned char) theArg.lexemeValue->contents[0]; \
	} \
	else \
	if (ERR == (VARIABLE_NAME = StrToACS(theArg.lexemeValue->contents))) \
	{ \
		WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": " #TH " arg must be a chtype\n"); \
		returnValue->lexemeValue = FalseSymbol(theEnv); \
		return; \
	} \
} \
else \
{ \
	WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": " #TH " arg must be a chtype\n"); \
	returnValue->lexemeValue = FalseSymbol(theEnv); \
	return; \
}

void NcursesborderFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int border(chtype ls, chtype rs, chtype ts, chtype bs, chtype tl, chtype tr, chtype bl, chtype br);
	PARSE_CHTYPE_ARG(border, ls, first)
	PARSE_CHTYPE_ARG(border, rs, second)
	PARSE_CHTYPE_ARG(border, ts, third)
	PARSE_CHTYPE_ARG(border, bs, fourth)
	PARSE_CHTYPE_ARG(border, tl, fifth)
	PARSE_CHTYPE_ARG(border, tr, sixth)
	PARSE_CHTYPE_ARG(border, bl, seventh)
	PARSE_CHTYPE_ARG(border, br, eighth)

	HANDLE_OK_OR_ERR(border, border(ls, rs, ts, bs, tl, tr, bl, br));
}

#define PARSE_WINDOW_ARG(FUNCTION_NAME)\
WINDOW *window = stdscr; \
UDFNextArgument(context,EXTERNAL_ADDRESS_BIT | SYMBOL_BIT,&theArg); \
if (theArg.header->type == SYMBOL_TYPE) \
{ \
	if (0 != strcmp("stdscr", theArg.lexemeValue->contents)) \
	{ \
		WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": first arg must be a WINDOW pointer or stdscr\n"); \
		returnValue->lexemeValue = FalseSymbol(theEnv); \
		return; \
	} \
} \
else \
if (theArg.header->type != EXTERNAL_ADDRESS_TYPE) \
{ \
	WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": first arg must be a WINDOW pointer or stdscr\n"); \
	returnValue->lexemeValue = FalseSymbol(theEnv); \
	return; \
} \
else \
{ \
	window = theArg.externalAddressValue->contents; \
}

void NcurseswborderFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int wborder(WINDOW *win, chtype ls, chtype rs, chtype ts, chtype bs, chtype tl, chtype tr, chtype bl, chtype br);
	PARSE_WINDOW_ARG(wborder)
	PARSE_CHTYPE_ARG(wborder, ls, second)
	PARSE_CHTYPE_ARG(wborder, rs, third)
	PARSE_CHTYPE_ARG(wborder, ts, fourth)
	PARSE_CHTYPE_ARG(wborder, bs, fifth)
	PARSE_CHTYPE_ARG(wborder, tl, sixth)
	PARSE_CHTYPE_ARG(wborder, tr, seventh)
	PARSE_CHTYPE_ARG(wborder, bl, eighth)
	PARSE_CHTYPE_ARG(wborder, br, ninth)

	HANDLE_OK_OR_ERR(wborder, wborder(window, ls, rs, ts, bs, tl, tr, bl, br));
}

void NcursesboxFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int box(WINDOW *win, chtype verch, chtype horch);
	PARSE_WINDOW_ARG(box)
	PARSE_CHTYPE_ARG(box, verch, second)
	PARSE_CHTYPE_ARG(box, horch, third)

	HANDLE_OK_OR_ERR(box, box(window, verch, horch));
}

#define PARSE_INTEGER_ARG(FUNCTION_NAME, VARIABLE_NAME, TH)\
UDFNextArgument(context,INTEGER_BIT,&theArg); \
int VARIABLE_NAME; \
if (theArg.header->type != INTEGER_TYPE) \
{ \
	WriteString(theEnv, STDERR, "ncurses-" #FUNCTION_NAME ": " #TH " arg must be an INTEGER\n"); \
	returnValue->lexemeValue = FalseSymbol(theEnv); \
	return; \
} \
VARIABLE_NAME = theArg.integerValue->contents;

void NcursesnewwinFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	WINDOW *window;
	// WINDOW * newwin(int nlines, int ncols, int begin_y, int begin_x);
	PARSE_INTEGER_ARG(newwin, nlines, first)
	PARSE_INTEGER_ARG(newwin, ncols, second)
	PARSE_INTEGER_ARG(newwin, begin_y, third)
	PARSE_INTEGER_ARG(newwin, begin_x, fourth)

	if (NULL == (window = newwin(nlines, ncols, begin_y, begin_x)))
	{
		WriteString(theEnv, STDERR, "ncurses-newwin: could not create new window\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	returnValue->externalAddressValue = CreateCExternalAddress(theEnv, window);
}

void NcurseswclearFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int wclear(WINDOW *win);
	PARSE_WINDOW_ARG(wclear)

	HANDLE_OK_OR_ERR(wclear, wclear(window));
}

void NcurseswrefreshFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int wrefresh(WINDOW *win);
	PARSE_WINDOW_ARG(wrefresh)

	HANDLE_OK_OR_ERR(wrefresh, wrefresh(window));
}

void NcursesmvwprintwFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int mvwprintw(WINDOW *win, int y, int x, const char *fmt, ...);
	PARSE_WINDOW_ARG(mvwprintw)
	PARSE_INTEGER_ARG(mvwprintw, y, second)
	PARSE_INTEGER_ARG(mvwprintw, x, third)

	UDFNextArgument(context, STRING_BIT, &theArg);
	if (theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, "ncurses-mvwprintw: fourth arg must be string\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	HANDLE_OK_OR_ERR(mvwprintw, mvwprintw(window, y, x, "%s", theArg.lexemeValue->contents))
}

void NcursesmoveFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int move(int y, int x);
	PARSE_INTEGER_ARG(move, x, first)
	PARSE_INTEGER_ARG(move, y, second)

	HANDLE_OK_OR_ERR(move, move(x, y))
}

void NcursesaddchFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int addch(const chtype ch);
	PARSE_CHTYPE_ARG(addch, ch, first)

	HANDLE_OK_OR_ERR(addch, addch(ch))
}

void NcursesinchFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->integerValue = CreateInteger(theEnv, inch());
}

void ChtypeCharacterFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	PARSE_CHTYPE_ARG(chtype-character, ch, first)
	returnValue->integerValue = CreateInteger(theEnv, A_CHARTEXT & ch);
}

void ChtypeAttributesFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	PARSE_CHTYPE_ARG(chtype-attributes, ch, first)
	returnValue->integerValue = CreateInteger(theEnv, A_ATTRIBUTES & ch);
}

void ChtypeColorPairFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	PARSE_CHTYPE_ARG(chtype-color-pair, ch, first)
	returnValue->integerValue = CreateInteger(theEnv, PAIR_NUMBER(ch));
}

void NcursestimeoutFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// void timeout(int delay);
	PARSE_INTEGER_ARG(timeout, delay, first)
	
	timeout(delay);
	
	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void NcurseswtimeoutFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// void wtimeout(WINDOW * win, int delay);
	PARSE_WINDOW_ARG(wtimeout)
	PARSE_INTEGER_ARG(wtimeout, delay, second)
	
	wtimeout(window, delay);

	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void NcursesgetyxFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	int x, y;
	// void getyx(WINDOW *win, int y, int x);
	PARSE_WINDOW_ARG(getyx)
	
	getyx(window, y, x);

	MultifieldBuilder *mb = CreateMultifieldBuilder(theEnv, 2);
	MBAppendInteger(mb, y);
	MBAppendInteger(mb, x);
	returnValue->multifieldValue = MBCreate(mb);
	MBDispose(mb);
}

void NcursesgetmaxyxFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	int x, y;
	// void getmaxyx(WINDOW *win, int y, int x);
	PARSE_WINDOW_ARG(getmaxyx)
	
	getmaxyx(window, y, x);

	MultifieldBuilder *mb = CreateMultifieldBuilder(theEnv, 2);
	MBAppendInteger(mb, y);
	MBAppendInteger(mb, x);
	returnValue->multifieldValue = MBCreate(mb);
	MBDispose(mb);
}

void NcursesdelwinFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	// int delwin(WINDOW * win);
	PARSE_WINDOW_ARG(delwin)

	HANDLE_OK_OR_ERR(delwin, delwin(window))
}

void NcursesattronFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	int attr = -1, in;
	while (UDFHasNextArgument(context))
	{
		UDFNextArgument(context,INTEGER_BIT | SYMBOL_BIT,&theArg);
		if (theArg.header->type == INTEGER_TYPE)
		{
			if (attr == -1)
			{
				attr = theArg.integerValue->contents;
			}
			else
			{
				attr |= theArg.integerValue->contents;
			}
		}
		else
		if (theArg.header->type == SYMBOL_TYPE)
		{
			if (in = StrToAttr(theArg.lexemeValue->contents))
			{	
				if (attr == -1)
				{
					attr = in;
				}
				else
				{
					attr |= in;
				}
			}
			else
			{
				WriteString(theEnv, STDERR, "ncurses-attron: Unrecognized attr ");
				WriteString(theEnv, STDERR, theArg.lexemeValue->contents);
				WriteString(theEnv, STDERR, "\n");
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			}
		}
	}
	if (attr > -1)
	{
		HANDLE_OK_OR_ERR(attron, attron(attr));
		return;
	}
	WriteString(theEnv, STDERR, "ncurses-attron: Unrecognized attrs\n");
	returnValue->lexemeValue = FalseSymbol(theEnv);
}

void NcursesattroffFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	int attr = -1, in;
	while (UDFHasNextArgument(context))
	{
		UDFNextArgument(context,INTEGER_BIT | SYMBOL_BIT,&theArg);
		if (theArg.header->type == INTEGER_TYPE)
		{
			if (attr == -1)
			{
				attr = theArg.integerValue->contents;
			}
			else
			{
				attr |= theArg.integerValue->contents;
			}
		}
		else
		if (theArg.header->type == SYMBOL_TYPE)
		{
			if (in = StrToAttr(theArg.lexemeValue->contents))
			{	
				if (attr == -1)
				{
					attr = in;
				}
				else
				{
					attr |= in;
				}
			}
			else
			{
				WriteString(theEnv, STDERR, "ncurses-attroff: Unrecognized attr ");
				WriteString(theEnv, STDERR, theArg.lexemeValue->contents);
				WriteString(theEnv, STDERR, "\n");
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			}
		}
	}
	if (attr > -1)
	{
		HANDLE_OK_OR_ERR(attroff, attroff(attr));
		return;
	}
	WriteString(theEnv, STDERR, "ncurses-attroff: Unrecognized attrs\n");
	returnValue->lexemeValue = FalseSymbol(theEnv);
}

void NcursescolsFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->integerValue = CreateInteger(theEnv, COLS);
}

void NcurseslinesFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->integerValue = CreateInteger(theEnv, LINES);
}

/*********************************************************/
/* UserFunctions: Informs the expert system environment  */
/*   of any user defined functions. In the default case, */
/*   there are no user defined functions. To define      */
/*   functions, either this function must be replaced by */
/*   a function with the same name within this file, or  */
/*   this function can be deleted from this file and     */
/*   included in another file.                           */
/*********************************************************/
#define ADD_UDF_HANDLE_OK_OR_ERR_FUNCTION(FUNCTION_NAME) \
AddUDF(env,"ncurses-" #FUNCTION_NAME,"by",0,0,NULL,Ncurses##FUNCTION_NAME##Function,"Ncurses" #FUNCTION_NAME "Function",NULL);


#define ADD_UDF_SET_OPTION(FUNCTION_NAME) \
AddUDF(env,"ncurses-" #FUNCTION_NAME,"by",0,2,";ey;b",Ncurses##FUNCTION_NAME##Function,"Ncurses" #FUNCTION_NAME "Function",NULL);

void UserFunctions(
  Environment *env)
  {
#if MAC_XCD
#pragma unused(env)
#endif
	AddUDF(env,"ncurses-initscr","be",0,0,NULL,NcursesinitscrFunction,"NcursesinitscrFunction",NULL);

	  ADD_UDF_HANDLE_OK_OR_ERR_FUNCTION(echo)
	  ADD_UDF_HANDLE_OK_OR_ERR_FUNCTION(noecho)
	  ADD_UDF_HANDLE_OK_OR_ERR_FUNCTION(cbreak)
	  ADD_UDF_HANDLE_OK_OR_ERR_FUNCTION(clear)
	  ADD_UDF_HANDLE_OK_OR_ERR_FUNCTION(refresh)
	  ADD_UDF_HANDLE_OK_OR_ERR_FUNCTION(endwin)
	  ADD_UDF_HANDLE_OK_OR_ERR_FUNCTION(doupdate)

	AddUDF(env,"ncurses-start-color","by",0,0,NULL,Ncursesstart_colorFunction,"Ncursesstart_colorFunction",NULL);

	  ADD_UDF_SET_OPTION(keypad)
	  ADD_UDF_SET_OPTION(leaveok)

	AddUDF(env,"ncurses-curs-set","bly",1,1,";l",NcursescurssetFunction,"NcursescurssetFunction",NULL);

	AddUDF(env,"ncurses-move","by",2,2,";l;l",NcursesmoveFunction,"NcursesmoveFunction",NULL);

	AddUDF(env,"ncurses-mvprintw","by",3,3,";l;l;s",NcursesmvprintwFunction,"NcursesmvprintwFunction",NULL);
	AddUDF(env,"ncurses-mvwprintw","by",4,4,";ey;l;l;s",NcursesmvwprintwFunction,"NcursesmvwprintwFunction",NULL);

	AddUDF(env,"ncurses-getch","bl",0,0,NULL,NcursesgetchFunction,"NcursesgetchFunction",NULL);
	AddUDF(env,"ncurses-key-to-str","bly",1,1,";l",NcurseskeyToStrFunction,"NcurseskeyToStrFunction",NULL);
	AddUDF(env,"ncurses-inch","l",0,0,NULL,NcursesinchFunction,"NcursesinchFunction",NULL);

	AddUDF(env,"ncurses-border","b",8,8,"y",NcursesborderFunction,"NcursesborderFunction",NULL);
	AddUDF(env,"ncurses-wborder","b",9,9,"y;ey",NcurseswborderFunction,"NcurseswborderFunction",NULL);
	AddUDF(env,"ncurses-box","b",3,3,"ly;ey",NcursesboxFunction,"NcursesboxFunction",NULL);

	AddUDF(env,"ncurses-newwin","b",4,4,"l",NcursesnewwinFunction,"NcursesnewwinFunction",NULL);
	AddUDF(env,"ncurses-wclear","b",0,1,";ey",NcurseswclearFunction,"NcurseswclearFunction",NULL);
	AddUDF(env,"ncurses-wrefresh","b",0,1,";ey",NcurseswrefreshFunction,"NcurseswrefreshFunction",NULL);

	AddUDF(env,"ncurses-addch","by",1,1,";l",NcursesaddchFunction,"NcursesaddchFunction",NULL);

	AddUDF(env,"ncurses-chtype-character","bl",1,1,";l",ChtypeCharacterFunction,"ChtypeCharacterFunction",NULL);
	AddUDF(env,"ncurses-chtype-attributes","bl",1,1,";l",ChtypeAttributesFunction,"ChtypeAttributesFunction",NULL);
	AddUDF(env,"ncurses-chtype-color-pair","bl",1,1,";l",ChtypeColorPairFunction,"ChtypeColorPairFunction",NULL);

	AddUDF(env,"ncurses-timeout","b",1,1,";l",NcursestimeoutFunction,"NcursestimeoutFunction",NULL);
	AddUDF(env,"ncurses-wtimeout","b",2,2,";ey;l",NcurseswtimeoutFunction,"NcurseswtimeoutFunction",NULL);
	AddUDF(env,"ncurses-getyx","bm",1,1,";ey",NcursesgetyxFunction,"NcursesgetyxFunction",NULL);
	AddUDF(env,"ncurses-getmaxyx","bm",1,1,";ey",NcursesgetmaxyxFunction,"NcursesgetmaxyxFunction",NULL);
	AddUDF(env,"ncurses-delwin","b",1,1,";ey",NcursesdelwinFunction,"NcursesdelwinFunction",NULL);

	AddUDF(env,"ncurses-attron","b",1,UNBOUNDED,"yl",NcursesattronFunction,"NcursesattronFunction",NULL);
	AddUDF(env,"ncurses-attroff","b",1,UNBOUNDED,"yl",NcursesattroffFunction,"NcursesattroffFunction",NULL);

	AddUDF(env,"ncurses-cols","l",0,0,NULL,NcursescolsFunction,"NcursescolsFunction",NULL);
	AddUDF(env,"ncurses-lines","l",0,0,NULL,NcurseslinesFunction,"NcurseslinesFunction",NULL);
  }
