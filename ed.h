/*	$OpenBSD: ed.h,v 1.22 2016/03/27 00:43:38 mmcc Exp $	*/
/*	$NetBSD: ed.h,v 1.23 1995/03/21 09:04:40 cgd Exp $	*/

/* ed.h: type and constant definitions for the ed editor. */
/*
 * Copyright (c) 1993 Andrew Moore
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	@(#)ed.h,v 1.5 1994/02/01 00:34:39 alm Exp
 */

#include "config.h"
#include <inttypes.h>
#include <limits.h>
#include <regex.h>
#include <stdbool.h>
#include <stdint.h>
#ifdef HAVE_PCRE2
# define PCRE2_CODE_UNIT_WIDTH 8
# include <pcre2.h>
#endif
#include <signal.h>

#define ERR		(-2)
#define EMOD		(-3)
#define FATAL		(-4)

#define MINBUFSZ 512		/* minimum buffer size - must be > 0 */
#define SE_MAX 30		/* max subexpressions in a regular expression */

/* Flags for ed_regexec */
#define ED_REG_STARTEND 1   /* use rm[0] as start/end of subject (cf REG_STARTEND) */
#define ED_REG_NOTBOL   2   /* subject start is not beginning of line */

/* Generic match-offset pair; used by ed_regexec */
typedef struct {
	int rm_so;
	int rm_eo;
} ed_match_t;

/* Compiled pattern wrapper: holds either a POSIX regex_t or a PCRE2 pattern */
typedef struct {
	bool is_pcre;		/* if set, use PCRE2 fields below */
	char *pat_str;		/* pattern string (for error messages) */
	int  nsub;		/* number of capturing subexpressions */
	regex_t *posix;		/* POSIX compiled pattern (non-PCRE path) */
#ifdef HAVE_PCRE2
	pcre2_code       *pcre_code;
	pcre2_match_data *pcre_mdata;
#endif
} ed_pattern_t;
#define LINECHARS INT_MAX	/* max chars per line */

/* gflags */
#define GLB 001		/* global command */
#define GPR 002		/* print after command */
#define GLS 004		/* list after command */
#define GNP 010		/* enumerate after command */
#define GSG 020		/* global substitute */
#define GHP 040		/* print hash before line */
#define GDR 0100	/* dry-run substitution (show result, don't apply) */
#define GAL 0200	/* all-or-nothing: fail unless every line in range matches */

/* Line node */
typedef struct	line {
	struct line	*q_forw;
	struct line	*q_back;
	off_t		seek;		/* address of line in scratch buffer */
	int		len;		/* length of line */
} line_t;


typedef struct undo {

/* type of undo nodes */
#define UADD	0
#define UDEL 	1
#define UMOV	2
#define VMOV	3

	int type;			/* command type */
	line_t	*h;			/* head of list */
	line_t  *t;			/* tail of list */
} undo_t;

#ifndef max
# define max(a,b) ((a) > (b) ? (a) : (b))
#endif
#ifndef min
# define min(a,b) ((a) < (b) ? (a) : (b))
#endif

/* inc_mod/dec_mod: modular increment/decrement within [0, k] */
static inline int inc_mod(int l, int k) { return l + 1 > k ? 0 : l + 1; }
static inline int dec_mod(int l, int k) { return l - 1 < 0 ? k : l - 1; }

/* SPL1: disable some interrupts (requires reliable signals) */
#define SPL1() mutex++

/* SPL0: enable all interrupts; check signal flags (requires reliable signals) */
#define SPL0()						\
	do {						\
		if (--mutex == 0) {			\
			if (sighup)			\
				handle_hup(SIGHUP);	\
			if (sigint)			\
				handle_int(SIGINT);	\
		}					\
	} while (0)

/* STRTOI: convert a string to int */
#define STRTOI(i, p) { \
	long l = strtol(p, &p, 10); \
	if (l <= INT_MIN || l >= INT_MAX) { \
		seterrmsg("number out of range"); \
	    	i = 0; \
		return ERR; \
	} else \
		i = (int)l; \
}

/* REALLOC: assure at least a minimum size for buffer b */
#define REALLOC(b,n,i,err) \
if ((i) > (n)) { \
	int ti = (n); \
	char *ts; \
	SPL1(); \
	if ((ts = realloc((b), ti += max((i), MINBUFSZ))) == NULL) { \
		perror(NULL); \
		seterrmsg("out of memory"); \
		SPL0(); \
		return err; \
	} \
	(n) = ti; \
	(b) = ts; \
	SPL0(); \
}

/* reque: link pred immediately before succ in the circular queue */
static inline void reque(line_t *pred, line_t *succ)
{
	pred->q_forw = succ;
	succ->q_back = pred;
}

/* insque: insert elem in circular queue after pred */
static inline void insque(line_t *elem, line_t *pred)
{
	reque(elem, pred->q_forw);
	reque(pred, elem);
}

/* remque: remove elem from circular queue */
static inline void remque(line_t *elem)
{
	reque(elem->q_back, elem->q_forw);
}

/* NUL_TO_NEWLINE: overwrite ASCII NULs with newlines */
#define NUL_TO_NEWLINE(s, l) translit_text(s, l, '\0', '\n')

/* NEWLINE_TO_NUL: overwrite newlines with ASCII NULs */
#define NEWLINE_TO_NUL(s, l) translit_text(s, l, '\n', '\0')

/* Local Function Declarations */
void quit(int);
void add_line_node(line_t *);
int build_active_list(int);
int get_active_count(void);
int get_undo_depth(void);
void clear_active_list(void);
void clear_undo_stack(void);
int close_sbuf(void);
int delete_lines(int, int);
int display_lines(int, int, int);
int exec_command(void);
int exec_global(int, int);
int extract_addr_range(void);
int extract_subst_tail(int *, int *);
line_t *get_addressed_line_node(int);
ed_pattern_t *get_compiled_pattern(void);
char *get_extended_line(int *, int);
int get_line_node_addr(line_t *);
char *get_sbuf_line(line_t *);
int get_tty_line(void);
void handle_hup(int);
void handle_int(int);
int has_trailing_escape(char *, char *);
void init_buffers(void);
int open_sbuf(void);
int pop_undo_stack(void);
undo_t *push_undo_stack(int, int, int);
char *put_sbuf_line(char *);
int put_tty_line(char *, int, int, int);
int search_and_replace(ed_pattern_t *, int, int, int, ed_pattern_t *);
int read_file(char *, int);
ed_pattern_t *ed_compile_pattern(const char *);
void ed_pattern_free(ed_pattern_t *);
int ed_regexec(ed_pattern_t *, const char *, int, ed_match_t *, int);
void seterrmsg(char *);
char *strip_escapes(char *);
char *translit_text(char *, int, int, int);
void unmark_line_node(line_t *);
void unset_active_nodes(line_t *, line_t *);
int write_file(char *, char *, int, int);
uint32_t adler32_line(const char *, int);

/* global buffers */
extern char *ibuf;
extern char *ibufp;
extern int ibufsz;

/* global flags */
extern bool isbinary;
extern bool isglobal;
extern bool modified;

extern volatile sig_atomic_t mutex;
extern volatile sig_atomic_t sighup;
extern volatile sig_atomic_t sigint;

/* global vars */
extern int addr_last;
extern int current_addr;
extern int first_addr;
extern int lineno;
extern int second_addr;
extern bool loose;
extern bool extended_re;
extern bool pcre_re;
extern bool always_number;
extern bool always_hash;
extern bool transact;
extern bool had_error;
extern int u_current_addr;
extern int last_nsubs;
extern int u_addr_last;
extern bool success_token;
extern bool readonly;
extern bool utf8_locale;
/* Additional globals not declared above (formerly via local extern) */
extern bool garrulous;
extern bool scripted;
extern bool patlock;
extern volatile sig_atomic_t rows;
extern volatile sig_atomic_t cols;
