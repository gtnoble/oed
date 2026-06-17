/*	$OpenBSD: re.c,v 1.19 2018/06/19 12:36:18 martijn Exp $	*/
/*	$NetBSD: re.c,v 1.14 1995/03/21 09:04:48 cgd Exp $	*/

/* re.c: This file contains the regular expression interface routines for
   the ed line editor. */
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

#include "config.h"

#include <regex.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ed.h"

static char *extract_pattern(int);
/* pattern_has_newline: scan pattern string for \n (backslash-n).
   Returns true if found outside of character classes, meaning the pattern
   intends multi-line matching. */
static bool
pattern_has_newline(const char *s)
{
	while (*s) {
		if (*s == '\\' && *(s + 1) == 'n')
			return true;
		if (*s == '[') {
			/* skip past character class */
			s++;
			if (*s == '^')
				s++;
			if (*s == ']')
				s++;
			while (*s && *s != ']') {
				if (*s == '\\')
					s++;
				if (*s)
					s++;
			}
			if (*s == ']')
				s++;
			continue;
		}
		s++;
	}
	return false;
}

static char *parse_char_class(char *);



/* ed_pattern_free: free an ed_pattern_t and all resources it owns */
void
ed_pattern_free(ed_pattern_t *pat)
{
	if (pat == NULL)
		return;
#ifdef HAVE_PCRE2
	if (pat->is_pcre) {
		pcre2_match_data_free(pat->pcre_mdata);
		pcre2_code_free(pat->pcre_code);
		free(pat->pat_str);
		free(pat);
		return;
	}
#endif
	regfree(pat->posix);
	free(pat->posix);
	free(pat->pat_str);
	free(pat);
}


/* ed_regexec: match pat against txt.
   If ED_REG_STARTEND is set in flags, rm[0].rm_so/rm_eo define the search
   window (equivalent to POSIX REG_STARTEND).
   If ED_REG_NOTBOL is set, the start of the window is not beginning-of-line.
   nmatch/rm may be 0/NULL for a match-only test.
   Returns 0 on match, 1 on no match, -1 on error. */
int
ed_regexec(ed_pattern_t *pat, const char *txt, int nmatch, ed_match_t *rm,
    int flags)
{
#ifdef HAVE_PCRE2
	if (pat->is_pcre) {
		int i, rc;
		PCRE2_SIZE startoffset = 0;
		PCRE2_SIZE length = PCRE2_ZERO_TERMINATED;
		uint32_t options = 0;
		PCRE2_SIZE *ovector;

		if (flags & ED_REG_STARTEND) {
			startoffset = (PCRE2_SIZE)rm[0].rm_so;
			length      = (PCRE2_SIZE)rm[0].rm_eo;
		}
		if (flags & ED_REG_NOTBOL)
			options |= PCRE2_NOTBOL;

		rc = pcre2_match(pat->pcre_code, (PCRE2_SPTR8)txt, length,
		    startoffset, options, pat->pcre_mdata, NULL);
		if (rc == PCRE2_ERROR_NOMATCH)
			return 1;
		if (rc < 0)
			return -1;
		if (nmatch > 0 && rm != NULL) {
			ovector = pcre2_get_ovector_pointer(pat->pcre_mdata);
			for (i = 0; i < nmatch && i < rc; i++) {
				rm[i].rm_so = (int)ovector[2 * i];
				rm[i].rm_eo = (int)ovector[2 * i + 1];
			}
			for (; i < nmatch; i++) {
				rm[i].rm_so = -1;
				rm[i].rm_eo = -1;
			}
		}
		return 0;
	}
#endif
	/* POSIX path */
	{
		regmatch_t posix_rm[SE_MAX];
		int posix_flags = 0;
		int rc;

		if (flags & ED_REG_STARTEND)
			posix_flags |= REG_STARTEND;
		if (flags & ED_REG_NOTBOL)
			posix_flags |= REG_NOTBOL;

		if (nmatch > 0 && rm != NULL) {
			if (flags & ED_REG_STARTEND) {
				posix_rm[0].rm_so = rm[0].rm_so;
				posix_rm[0].rm_eo = rm[0].rm_eo;
			}
			rc = regexec(pat->posix, txt, (size_t)nmatch, posix_rm,
			    posix_flags);
			if (rc != 0)
				return 1;
			for (int i = 0; i < nmatch; i++) {
				rm[i].rm_so = (int)posix_rm[i].rm_so;
				rm[i].rm_eo = (int)posix_rm[i].rm_eo;
			}
		} else {
			rc = regexec(pat->posix, txt, 0, NULL, posix_flags);
			if (rc != 0)
				return 1;
		}
		return 0;
	}
}


/* get_compiled_pattern: return pointer to compiled pattern from command
   buffer */
ed_pattern_t *
get_compiled_pattern(void)
{
	static ed_pattern_t *exp = NULL;
	char errbuf[128] = "";

	char *exps;
	char delimiter;

	if ((delimiter = *ibufp) == ' ') {
		seterrmsg("invalid pattern delimiter");
		return NULL;
	} else if (delimiter == '\n' || *++ibufp == '\n' || *ibufp == delimiter) {
		if (!exp)
			seterrmsg("no previous pattern");
		return exp;
	} else if ((exps = extract_pattern(delimiter)) == NULL)
		return NULL;

	/* free previous pattern if not reserved */
	if (exp && !patlock)
		ed_pattern_free(exp);
	exp = NULL;
	patlock = 0;

#ifdef HAVE_PCRE2
	if (pcre_re) {
		int errcode;
		PCRE2_SIZE erroffset;
		uint32_t capturecount;
		pcre2_code *code;
		pcre2_match_data *mdata;
		PCRE2_UCHAR8 pcre_errbuf[128];

		if ((exp = malloc(sizeof(ed_pattern_t))) == NULL) {
			perror(NULL);
			seterrmsg("out of memory");
			return NULL;
		}
		exp->pat_str = NULL;
		code = pcre2_compile((PCRE2_SPTR8)exps, PCRE2_ZERO_TERMINATED,
		    PCRE2_UTF | PCRE2_MATCH_INVALID_UTF, &errcode, &erroffset, NULL);
		if (code == NULL) {
			pcre2_get_error_message(errcode, pcre_errbuf,
			    sizeof(pcre_errbuf));
			seterrmsg((char *)pcre_errbuf);
			free(exp);
			return exp = NULL;
		}
		pcre2_pattern_info(code, PCRE2_INFO_CAPTURECOUNT, &capturecount);
		mdata = pcre2_match_data_create_from_pattern(code, NULL);
		if (mdata == NULL) {
			pcre2_code_free(code);
			seterrmsg("out of memory");
			free(exp);
			return exp = NULL;
		}
		exp->is_pcre    = 1;
		exp->nsub       = (int)capturecount;
		exp->multiline = pattern_has_newline(exps);
		exp->posix      = NULL;
		exp->pcre_code  = code;
		exp->pcre_mdata = mdata;
		{
			size_t n = strlen(exps) + 1;
			if ((exp->pat_str = malloc(n)) != NULL)
				memcpy(exp->pat_str, exps, n);
		}
		return exp;
	}
#endif

	/* POSIX path */
	{
		int n;

		if ((exp = malloc(sizeof(ed_pattern_t))) == NULL) {
			perror(NULL);
			seterrmsg("out of memory");
			return NULL;
		}
		exp->pat_str = NULL;
		if ((exp->posix = malloc(sizeof(regex_t))) == NULL) {
			perror(NULL);
			seterrmsg("out of memory");
			free(exp);
			return exp = NULL;
		}
		exp->is_pcre = 0;
		if ((n = regcomp(exp->posix, exps,
		    extended_re ? REG_EXTENDED : 0)) != 0) {
			regerror(n, exp->posix, errbuf, sizeof errbuf);
			seterrmsg(errbuf);
			free(exp->posix);
			free(exp);
			return exp = NULL;
		}
		exp->nsub = (int)exp->posix->re_nsub;
		exp->multiline = pattern_has_newline(exps);
		{
			size_t n = strlen(exps) + 1;
			if ((exp->pat_str = malloc(n)) != NULL)
				memcpy(exp->pat_str, exps, n);
		}
		return exp;
	}
}


/* extract_pattern: copy a pattern string from the command buffer; return
   pointer to the copy */
static char *
extract_pattern(int delimiter)
{
	static char *lhbuf = NULL;	/* buffer */
	static int lhbufsz = 0;		/* buffer size */

	char *nd;
	int len;

	for (nd = ibufp; *nd != delimiter && *nd != '\n'; nd++)
		switch (*nd) {
		default:
			break;
		case '[':
			if ((nd = parse_char_class(++nd)) == NULL) {
				seterrmsg("unbalanced brackets ([])");
				return NULL;
			}
			break;
		case '\\':
			if (*++nd == '\n') {
				seterrmsg("trailing backslash (\\)");
				return NULL;
			}
			break;
		}
	len = nd - ibufp;
	REALLOC(lhbuf, lhbufsz, len + 1, NULL);
	memcpy(lhbuf, ibufp, len);
	lhbuf[len] = '\0';
	ibufp = nd;
	return (isbinary) ? NUL_TO_NEWLINE(lhbuf, len) : lhbuf;
}


/* parse_char_class: expand a POSIX character class */
static char *
parse_char_class(char *s)
{
	int c, d;

	if (*s == '^')
		s++;
	if (*s == ']')
		s++;
	for (; *s != ']' && *s != '\n'; s++)
		if (*s == '[' && ((d = *(s+1)) == '.' || d == ':' || d == '='))
			for (s++, c = *++s; *s != ']' || c != d; s++)
				if ((c = *s) == '\n')
					return NULL;
	return  (*s == ']') ? s : NULL;
}


/* ed_compile_pattern: compile a pattern string without touching global state.
   Returns a newly allocated ed_pattern_t that the caller must free with
   ed_pattern_free(), or NULL on error. */
ed_pattern_t *
ed_compile_pattern(const char *str)
{
	char errbuf[128];
	ed_pattern_t *p;

#ifdef HAVE_PCRE2
	if (pcre_re) {
		int errcode;
		PCRE2_SIZE erroffset;
		uint32_t capturecount;
		pcre2_match_data *mdata;
		pcre2_code *code;
		PCRE2_UCHAR8 pcre_errbuf[128];

		if ((p = malloc(sizeof(ed_pattern_t))) == NULL) {
			seterrmsg("out of memory");
			return NULL;
		}
		p->pat_str = NULL;
		code = pcre2_compile((PCRE2_SPTR8)str, PCRE2_ZERO_TERMINATED,
		    PCRE2_UTF | PCRE2_MATCH_INVALID_UTF, &errcode, &erroffset, NULL);
		if (code == NULL) {
			pcre2_get_error_message(errcode, pcre_errbuf,
			    sizeof(pcre_errbuf));
			seterrmsg((char *)pcre_errbuf);
			free(p);
			return NULL;
		}
		pcre2_pattern_info(code, PCRE2_INFO_CAPTURECOUNT, &capturecount);
		mdata = pcre2_match_data_create_from_pattern(code, NULL);
		if (mdata == NULL) {
			pcre2_code_free(code);
			seterrmsg("out of memory");
			free(p);
			return NULL;
		}
		p->is_pcre    = 1;
		p->nsub       = (int)capturecount;
		p->multiline = pattern_has_newline(str);
		p->posix      = NULL;
		p->pcre_code  = code;
		p->pcre_mdata = mdata;
		{
			size_t n = strlen(str) + 1;
			if ((p->pat_str = malloc(n)) != NULL)
				memcpy(p->pat_str, str, n);
		}
		return p;
	}
#endif

	/* POSIX path */
	errbuf[0] = '\0';
	if ((p = malloc(sizeof(ed_pattern_t))) == NULL) {
		seterrmsg("out of memory");
		return NULL;
	}
	p->pat_str = NULL;
	if ((p->posix = malloc(sizeof(regex_t))) == NULL) {
		seterrmsg("out of memory");
		free(p);
		return NULL;
	}
	p->is_pcre = 0;
	{
		int n;
		if ((n = regcomp(p->posix, str,
		    extended_re ? REG_EXTENDED : 0)) != 0) {
			regerror(n, p->posix, errbuf, sizeof errbuf);
			seterrmsg(errbuf);
			free(p->posix);
			free(p);
			return NULL;
		}
	}
	p->nsub = (int)p->posix->re_nsub;
	p->multiline = pattern_has_newline(str);
	{
		size_t n = strlen(str) + 1;
		if ((p->pat_str = malloc(n)) != NULL)
			memcpy(p->pat_str, str, n);
	}
	return p;
}
