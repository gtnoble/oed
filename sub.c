/*	$OpenBSD: sub.c,v 1.18 2016/10/11 06:54:05 martijn Exp $	*/
/*	$NetBSD: sub.c,v 1.4 1995/03/21 09:04:50 cgd Exp $	*/

/* sub.c: This file contains the substitution routines for the ed
   line editor */
/*-
 * Copyright (c) 1993 Andrew Moore, Talke Studio.
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
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <limits.h>
#include <regex.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ed.h"

static char *extract_subst_template(void);
static int substitute_matching_text(ed_pattern_t *, line_t *, int, int);
static int apply_subst_template(char *, ed_match_t *, int, int, bool);

static char *rhbuf;		/* rhs substitution buffer */
static int rhbufsz;		/* rhs substitution buffer size */
static int rhbufi;		/* rhs substitution buffer index */

/* extract_subst_tail: extract substitution tail from the command buffer */
int
extract_subst_tail(int *flagp, int *np)
{
	char delimiter;

	*flagp = *np = 0;
	if ((delimiter = *ibufp) == '\n') {
		rhbufi = 0;
		*flagp = GPR;
		return 0;
	} else if (extract_subst_template() == NULL)
		return  ERR;
	else if (*ibufp == '\n') {
		*flagp = GPR;
		return 0;
	} else if (*ibufp == delimiter)
		ibufp++;
	if ('1' <= *ibufp && *ibufp <= '9') {
		STRTOI(*np, ibufp);
		return 0;
	} else if (*ibufp == 'g') {
		ibufp++;
		*flagp = GSG;
		return 0;
	}
	return 0;
}


/* extract_subst_template: return pointer to copy of substitution template
   in the command buffer */
static char *
extract_subst_template(void)
{
	int n = 0;
	int i = 0;
	char c;
	char delimiter = *ibufp++;

	if (*ibufp == '%' && *(ibufp + 1) == delimiter) {
		ibufp++;
		if (!rhbuf)
			seterrmsg("no previous substitution");
		return rhbuf;
	}
	while (*ibufp != delimiter) {
		REALLOC(rhbuf, rhbufsz, i + 2, NULL);
		if ((c = rhbuf[i++] = *ibufp++) == '\n' && *ibufp == '\0') {
			i--, ibufp--;
			break;
		} else if (c != '\\')
			;
		else if ((rhbuf[i++] = *ibufp++) != '\n')
			;
		else if (!isglobal) {
			while ((n = get_tty_line()) == 0 ||
			    (n > 0 && ibuf[n - 1] != '\n'))
				clearerr(stdin);
			if (n < 0)
				return NULL;
		}
	}
	REALLOC(rhbuf, rhbufsz, i + 1, NULL);
	rhbuf[rhbufi = i] = '\0';
	return  rhbuf;
}


static char *rbuf;		/* substitute_matching_text buffer */
static int rbufsz;		/* substitute_matching_text buffer size */

/* search_and_replace: for each line in a range, change text matching a pattern
   according to a substitution template; return status  */
int
search_and_replace(ed_pattern_t *pat, int gflag, int kth, int exact_count,
    ed_pattern_t *verify_pat)
{
	undo_t *up;
	char *txt;
	char *eot;
	int lc;
	int xa = current_addr;
	int nsubs = 0;
	line_t *lp;
	int len;
	int range_size = second_addr - first_addr + 1;

	/* Multi-line matching path: when pattern contains \n, concatenate
	   all lines in the address range and match across line boundaries. */
	if (pat->multiline) {
		int concat_len = 0, concat_sz = 0;
		char *concat = NULL;
		int scan = 0;
		int nempty = -1;
		int matchno = 0;
		int off = 0;
		int i2 = 0;
		ed_match_t rm[SE_MAX];

		/* Build concatenated buffer of all lines in range */
		for (lc = 0; lc < range_size; lc++) {
			lp = get_addressed_line_node(first_addr + lc);
			txt = get_sbuf_line(lp);
			if (txt == NULL) {
				free(concat);
				return ERR;
			}
			len = lp->len;
			REALLOC(concat, concat_sz, concat_len + len + 1, ERR);
			memcpy(concat + concat_len, txt, len);
			concat_len += len;
			if (lc < range_size - 1)
				concat[concat_len++] = '\n';
		}

		if (isbinary) {
			seterrmsg("multi-line substitution not"
			    " supported on binary files");
			free(concat);
			return ERR;
		}

		/* Match pattern against the concatenated buffer */
		while (scan < concat_len) {
			rm[0].rm_so = scan;
			rm[0].rm_eo = concat_len;
			if (ed_regexec(pat, concat, SE_MAX, rm,
			    ED_REG_STARTEND) != 0)
				break;
			/* Skip zero-length match after non-zero-length */
			if (rm[0].rm_eo == nempty) {
				rm[0].rm_so++;
				continue;
			}
			if (!kth || kth == ++matchno) {
				/* Copy text before this match */
				i2 = rm[0].rm_so - scan;
				REALLOC(rbuf, rbufsz, off + i2, ERR);
				memcpy(rbuf + off, concat + scan, i2);
				off += i2;
				/* Apply substitution template */
				if ((off = apply_subst_template(concat, rm,
				    off, pat->nsub, pat->literal_repl)) < 0) {
					free(concat);
					return ERR;
				}
				nsubs++;
			}
			/* Advance past this match */
			scan = rm[0].rm_eo;
			if (rm[0].rm_so == rm[0].rm_eo)
				scan = rm[0].rm_eo + 1;
			else
				nempty = rm[0].rm_so = rm[0].rm_eo;
			if (!(gflag & GSG) && !kth)
				break;
			if (kth && matchno >= kth)
				break;
		}

		/* Copy remaining text after last match */
		i2 = concat_len - scan;
		REALLOC(rbuf, rbufsz, off + i2 + 2, ERR);
		if (i2 > 0)
			memcpy(rbuf + off, concat + scan, i2);
		off += i2;
		/* Ensure trailing newline */
		rbuf[off++] = '\n';
		rbuf[off] = '\0';

		free(concat);

		/* If no matches, report error */
		if (nsubs == 0 && !(gflag & GLB)) {
			if (pat->pat_str != NULL) {
				char buf[256];
				snprintf(buf, sizeof(buf),
				    "no match for pattern \"%s\"",
				    pat->pat_str);
				seterrmsg(buf);
			} else {
				seterrmsg("no match");
			}
			return ERR;
		}

		/* Verify each result line */
		if (verify_pat != NULL) {
			char *vline = rbuf;
			char *vend  = rbuf + off;
			while (vline != vend) {
				char *vnl = vline;
				while (vnl < vend && *vnl != '\n')
					vnl++;
				{
					char save = *vnl;
					*vnl = '\0';
					if (ed_regexec(verify_pat, vline,
					    0, NULL, 0) != 0) {
						*vnl = save;
						seterrmsg("result did not"
						    " match verify pattern");
						if (nsubs > 0 &&
						    !(gflag & GDR))
							pop_undo_stack();
						return ERR;
					}
					*vnl = save;
				}
				vline = (vnl < vend) ? vnl + 1 : vend;
			}
		}

		/* Dry-run: print result lines, skip buffer write */
		if (gflag & GDR) {
			txt = rbuf;
			eot = rbuf + off;
			do {
				char *nl = txt;
				while (nl < eot && *nl != '\n')
					nl++;
				put_tty_line(txt, (int)(nl - txt),
				    current_addr, gflag);
				txt = (nl < eot) ? nl + 1 : eot;
			} while (txt != eot);
			xa = current_addr;
		} else {
			/* Delete entire original range,
			   insert all result lines */
			if (delete_lines(first_addr,
			    second_addr) < 0)
				return ERR;
			up = NULL;
			txt = rbuf;
			eot = rbuf + off;
			SPL1();
			do {
				if ((txt = put_sbuf_line(txt))
				    == NULL) {
					SPL0();
					return ERR;
				} else if (up)
					up->t =
					    get_addressed_line_node(
					    current_addr);
				else if ((up = push_undo_stack(
				    UADD, current_addr,
				    current_addr)) == NULL) {
					SPL0();
					return ERR;
				}
			} while (txt != eot);
			SPL0();
			xa = current_addr;
		}

		/* All-or-nothing: must have matched */
		if ((gflag & GAL) && nsubs == 0) {
			seterrmsg(
			    "not all lines in range matched");
			if (nsubs > 0 && !(gflag & GDR))
				pop_undo_stack();
			return ERR;
		}

		/* Exact count assertion */
		if (exact_count >= 0 && nsubs != exact_count) {
			seterrmsg("substitution count mismatch");
			if (nsubs > 0 && !(gflag & GDR))
				pop_undo_stack();
			return ERR;
		}

		current_addr = xa;
		last_nsubs = nsubs;
		if (garrulous)
			fprintf(stderr, "%d substitution(s)\n",
			    nsubs);
		if (!(gflag & GDR) &&
		    (gflag & (GPR | GLS | GNP)) &&
		    display_lines(current_addr, current_addr,
		    gflag) < 0)
			return ERR;
		return nsubs;
	}



	current_addr = first_addr - 1;
	for (lc = 0; lc <= second_addr - first_addr; lc++) {
		lp = get_addressed_line_node(++current_addr);
		if ((len = substitute_matching_text(pat, lp, gflag, kth)) < 0)
			return ERR;
		else if (len) {
			/* verify result against verify_pat before committing */
			if (verify_pat != NULL) {
				char *vline = rbuf;
				char *vend  = rbuf + len;
				while (vline != vend) {
					char *vnl = vline;
					while (vnl < vend && *vnl != '\n')
						vnl++;
					/* temporarily NUL-terminate for regexec */
					{
						char save = *vnl;
						*vnl = '\0';
						if (ed_regexec(verify_pat, vline,
						    0, NULL, 0) != 0) {
							*vnl = save;
							seterrmsg(
							    "result did not match verify pattern");
							if (nsubs > 0 &&
							    !(gflag & GDR))
								pop_undo_stack();
							return ERR;
						}
						*vnl = save;
					}
					vline = (vnl < vend) ? vnl + 1 : vend;
				}
			}
			/* dry-run: print result lines, skip buffer write */
			if (gflag & GDR) {
				txt = rbuf;
				eot = rbuf + len;
				do {
					char *nl = txt;
					while (nl < eot && *nl != '\n')
						nl++;
					put_tty_line(txt, (int)(nl - txt),
					    current_addr, gflag);
					txt = (nl < eot) ? nl + 1 : eot;
				} while (txt != eot);
				nsubs++;
				xa = current_addr;
			} else {
				up = NULL;
				if (delete_lines(current_addr, current_addr) < 0)
					return ERR;
				txt = rbuf;
				eot = rbuf + len;
				SPL1();
				do {
					if ((txt = put_sbuf_line(txt)) == NULL) {
						SPL0();
						return ERR;
					} else if (up)
						up->t = get_addressed_line_node(
						    current_addr);
					else if ((up = push_undo_stack(UADD,
					    current_addr,
					    current_addr)) == NULL) {
						SPL0();
						return ERR;
					}
				} while (txt != eot);
				SPL0();
				nsubs++;
				xa = current_addr;
			}
		}
	}
	current_addr = xa;
	if (nsubs == 0 && !(gflag & GLB)) {
	if (pat->pat_str != NULL) {
		char buf[256];
		snprintf(buf, sizeof(buf), "no match for pattern \"%s\"",
		    pat->pat_str);
		seterrmsg(buf);
	} else {
		seterrmsg("no match");
	}
		return ERR;
	}
	/* all-or-nothing: every line in range must have matched */
	if ((gflag & GAL) && nsubs != range_size) {
		seterrmsg("not all lines in range matched");
		if (nsubs > 0 && !(gflag & GDR))
			pop_undo_stack();
		return ERR;
	}
	/* exact count assertion */
	if (exact_count >= 0 && nsubs != exact_count) {
		seterrmsg("substitution count mismatch");
		if (nsubs > 0 && !(gflag & GDR))
			pop_undo_stack();
		return ERR;
	}
	last_nsubs = nsubs;
	if (garrulous)
		fprintf(stderr, "%d substitution(s)\n", nsubs);
	if (!(gflag & GDR) && (gflag & (GPR | GLS | GNP)) &&
	    display_lines(current_addr, current_addr, gflag) < 0)
		return ERR;
	return nsubs;
}


/* substitute_matching_text: replace text matched by a pattern according to
   a substitution template; return length of rbuf if changed, 0 if unchanged, or
   ERR on error */
static int
substitute_matching_text(ed_pattern_t *pat, line_t *lp, int gflag, int kth)
{
	int off = 0;
	int changed = 0;
	int matchno = 0;
	int i = 0;
	int nempty = -1;
	ed_match_t rm[SE_MAX];
	char *txt;
	char *eot, *eom;

	if ((eom = txt = get_sbuf_line(lp)) == NULL)
		return ERR;
	if (isbinary)
		NUL_TO_NEWLINE(txt, lp->len);
	eot = txt + lp->len;
	if (!ed_regexec(pat, txt, SE_MAX, rm, 0)) {
		do {
/* Don't do a 0-length match directly after a non-0-length */
			if (rm[0].rm_eo == nempty) {
				rm[0].rm_so++;
				rm[0].rm_eo = lp->len;
				continue;
			}
			if (!kth || kth == ++matchno) {
				changed = 1;
				i = rm[0].rm_so - (eom - txt);
				REALLOC(rbuf, rbufsz, off + i, ERR);
				if (isbinary)
					NEWLINE_TO_NUL(eom,
					    rm[0].rm_eo - (eom - txt));
				memcpy(rbuf + off, eom, i);
				off += i;
			if ((off = apply_subst_template(txt, rm, off,
			    pat->nsub, pat->literal_repl)) < 0)
					return ERR;
				eom = txt + rm[0].rm_eo;
				if (kth)
					break;
			}
			if (rm[0].rm_so == rm[0].rm_eo)
				rm[0].rm_so = rm[0].rm_eo + 1;
			else
				nempty = rm[0].rm_so = rm[0].rm_eo;
			rm[0].rm_eo = lp->len;
		} while (rm[0].rm_so < lp->len && (gflag & GSG || kth) &&
		    !ed_regexec(pat, txt, SE_MAX, rm, ED_REG_STARTEND | ED_REG_NOTBOL));
		i = eot - eom;
		REALLOC(rbuf, rbufsz, off + i + 2, ERR);
		if (isbinary)
			NEWLINE_TO_NUL(eom, i);
		memcpy(rbuf + off, eom, i);
		memcpy(rbuf + off + i, "\n", 2);
	}
	return changed ? off + i + 1 : 0;
}


/* apply_subst_template: modify text according to a substitution template;
   return offset to end of modified text */
static int
apply_subst_template(char *boln, ed_match_t *rm, int off, int re_nsub, bool literal_repl)
{
	if (literal_repl) {
		int rlen = rhbufi;
		REALLOC(rbuf, rbufsz, off + rlen + 1, ERR);
		memcpy(rbuf + off, rhbuf, rlen);
		off += rlen;
		rbuf[off] = '\0';
		return off;
	}
	int j = 0;
	int k = 0;
	int n;
	char *sub = rhbuf;

	for (; sub - rhbuf < rhbufi; sub++)
		if (*sub == '&') {
			j = rm[0].rm_so;
			k = rm[0].rm_eo;
			REALLOC(rbuf, rbufsz, off + k - j, ERR);
			while (j < k)
				rbuf[off++] = boln[j++];
		} else if (*sub == '\\') {
			char esc = *++sub;
			if ('1' <= esc && esc <= '9' &&
			    (n = esc - '0') <= re_nsub) {
				j = rm[n].rm_so;
				k = rm[n].rm_eo;
				REALLOC(rbuf, rbufsz, off + k - j, ERR);
				while (j < k)
					rbuf[off++] = boln[j++];
			} else if (esc == 'n') {
				/* \\n in replacement -> literal newline */
				REALLOC(rbuf, rbufsz, off + 1, ERR);
				rbuf[off++] = '\n';
			} else if (esc == 't') {
				/* \\t in replacement -> literal tab */
				REALLOC(rbuf, rbufsz, off + 1, ERR);
				rbuf[off++] = '\t';
			} else {
				/* unrecognized escape: emit character literally
				   (same as old behaviour — backslash dropped) */
				REALLOC(rbuf, rbufsz, off + 1, ERR);
				rbuf[off++] = esc;
			}
		} else {
			REALLOC(rbuf, rbufsz, off + 1, ERR);
			rbuf[off++] = *sub;
		}
	REALLOC(rbuf, rbufsz, off + 1, ERR);
	rbuf[off] = '\0';
	return off;
}

/* set_rhbuf: copy a prepared replacement string (with \n/\t already
   resolved) into the global rhbuf.  Called by the R command. */
int
set_rhbuf(const char *repl, int len)
{
	int i;
	for (i = 0; i < len; i++) {
		REALLOC(rhbuf, rhbufsz, i + 2, ERR);
		rhbuf[i] = repl[i];
	}
	REALLOC(rhbuf, rhbufsz, i + 1, ERR);
	rhbuf[i] = '\0';
	rhbufi = i;
	return 0;
}
