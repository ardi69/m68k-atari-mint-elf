// vfork_exec.cpp : Definiert den Einstiegspunkt f�r die Konsolenanwendung.
//
#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <malloc.h>

#define A_ELF "a.elf"
#define A_OUT "a.out"

#define STRINGIZE(x) STRINGIZE2(x)
#define STRINGIZE2(x) #x
#define LINE_STRING STRINGIZE(__LINE__)

struct {
	const char *option;
	enum {
		OPTION_WITH_NO = 1 << 0,
		OPTION_WITH_ARG = 1 << 1
	} flags;
} tostool_opts[] = {
	{ "fastload", OPTION_WITH_NO },
	{ "altram", OPTION_WITH_NO },
	{ "fastram", OPTION_WITH_NO },
	{ "altalloc", OPTION_WITH_NO },

	{ "best-fit", OPTION_WITH_NO },
	{ "sharable-text", OPTION_WITH_NO },
	{ "shared-text", OPTION_WITH_NO },
	{ "baserel", OPTION_WITH_NO },

	{ "private-memory", },
	{ "global-memory", },
	{ "super-memory", },
	{ "readonly-memory", },
	{ "readable-memory", },
	{ "prg-flags", OPTION_WITH_ARG },
	{ "stack", OPTION_WITH_ARG },

};




#ifdef _WIN32

#include <process.h>
// extern char **environ; already defined in stdlib.h


#ifdef _MSC_VER
#define alloca _alloca
#define strcasecmp _stricmp
#endif
int vfork_exec(char *argv[], char *env[]) {
	return _spawnve(_P_WAIT, argv[0], (const char * const *)argv, (const char * const *)env);
}
#else

#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>
extern char **environ;

int vfork_exec(char * argv[], char * env[]) {
	pid_t pid;
	int status;

	pid = vfork();
	if (pid < 0) {
		return -1;
	}
	else if (pid == 0) {
		execve(argv[0], argv, env ? env : environ);
		perror("execve() failure");
		_exit(1);
	} else {
		waitpid(pid, &status, 0);
		return status;
	}
}
#endif

#if 0
static void print_environ() {
	int i = 1;
	char *s = *environ;
	printf("environ:\n");
	for (; s; i++) {
		printf("%s\n", s);
		s = *(environ + i);
	}
}
#endif

#ifdef SHOW_ARGS
static void print_args(const char *prg, int argc, char *argv[]) {
	int arg;
	printf("%s ", prg);
	for (arg = 0; arg < argc; ++arg) printf("%s ", argv[arg]);
	printf("\n");
}
#else
#	define print_args(...) do{}while(0)
#endif

static void fatal(const char *msg) {
	perror(msg);
	exit(1);
}


static char *getFileName(char *PathFileName) {
	char *p = strrchr(PathFileName, '/'); // find last slash
#ifdef _WIN32
	if (!p)	p = strrchr(PathFileName, '\\');
#endif
	if (p) ++p; // skip slash
	return p ?: PathFileName;
}

static char *getFileExt(char *PathFileName) {
	return strrchr(getFileName(PathFileName), '.'); // find last dot in filename
}

int main(int argc, char *argv[]) {
	char **ld_argv, **tostool_argv;
	int ld_argc = 1, tostool_argc = 1, arg_idx, idx, no, keep_elf = 0, no_tostool = 0, ld_output_idx = 0, help = 0;
	char *p, *tostool_input = A_ELF, *tostool_output = A_OUT;
	const char *exe = "";

	print_args("ld-hijacker", argc, argv);

	// allocate argv for ld & tostool - add space of 10 extra args
	if(!(ld_argv = (char**)malloc(sizeof(char*)*(argc + 10)))) fatal("out of memory @" LINE_STRING);
	if(!(tostool_argv = (char**)malloc(sizeof(char*)*(argc + 10)))) fatal("out of memory @" LINE_STRING);

	ld_argv[0] = (char*)malloc(strlen(argv[0]) + sizeof(".elf"));

	// prepare ld_argv[0] -> append ".elf" but leaf an optional ".exe" at last
	p = getFileExt(argv[0]);
	if (p && !strcasecmp(p, ".exe")) {
		exe = p;
		strncpy(ld_argv[0], argv[0], p - argv[0]); ld_argv[0][p - argv[0]] = 0;
		strcat(ld_argv[0], ".elf");
		strcat(ld_argv[0], p);
	} else {
		strcpy(ld_argv[0], argv[0]);
		strcat(ld_argv[0], ".elf");
	}

	// prepare tostool_argv[0] -> remove filename from arg[0] and append "tostool" but leaf ".exe"
	if ((p = getFileName(argv[0]))) {
		if(!(tostool_argv[0] = (char*)malloc((p - argv[0]) + strlen("tostool") + strlen(exe) + sizeof('\0')))) fatal("out of memory @" LINE_STRING);
		strncpy(tostool_argv[0], argv[0], (p - argv[0])); tostool_argv[0][p - argv[0]] = 0;
		strcat(tostool_argv[0], "tostool");
		strcat(tostool_argv[0], exe);
	} else {
		if(!(tostool_argv[0] = (char*)malloc(strlen("tostool") + strlen(exe) + sizeof('\0')))) fatal("out of memory@" LINE_STRING);
		strcpy(tostool_argv[0], "tostool");
		strcat(tostool_argv[0], exe);
	}

	// indicate tostool is invoked by ld-hijacker
	tostool_argv[tostool_argc++] = "--ld-hijacker"; 

	// assign args to ld and/or tostool
	for (arg_idx = 1; arg_idx < argc; ++arg_idx) {
		if (!strcmp(argv[arg_idx], "-h")) {
			ld_argv[ld_argc++] = "--help";
			tostool_argv[tostool_argc++] = argv[arg_idx];
			keep_elf = 1;  // ld --help don't output an elf-file -> keep_elf == don't delete elf

		} else if (!strcmp(argv[arg_idx], "-v") || !strcmp(argv[arg_idx], "--gc-sections")) {
			ld_argv[ld_argc++] = tostool_argv[tostool_argc++] = argv[arg_idx]; // simple pass truth

		} else if (!strcmp(argv[arg_idx], "--help") || !strcmp(argv[arg_idx], "--target-help")) {
			ld_argv[ld_argc++] = tostool_argv[tostool_argc++] = argv[arg_idx];
			keep_elf = help = 1;  // ld --help don't output an elf-file -> keep_elf == don't delete elf

		} else if (!strcmp(argv[arg_idx], "--strip-all") || !strcmp(argv[arg_idx], "-s")) {
			// ignore strip-all

		} else if (!strcmp(argv[arg_idx], "--keep-elf")) {
			keep_elf = 1; // don't delete elf

		} else if (!strncmp(argv[arg_idx], "-o", 2)) {
			if(argv[arg_idx][2]) {
				// -oFilename -> split to -o Filename
				ld_argv[ld_argc++] = "-o";
				ld_argv[(ld_output_idx = ld_argc++)] = &argv[arg_idx][2];
			} else {
				// -o Filename
				if ((arg_idx + 1) >= argc) fatal("no output given");
				ld_argv[ld_argc++] = argv[arg_idx++];
				ld_argv[(ld_output_idx = ld_argc++)] = argv[arg_idx];
			}

		} else if (!strncmp(argv[arg_idx], "--", 2) || !strncmp(argv[arg_idx], "-m", 2)) { // enable --option an -moption
			p = &argv[arg_idx][2];
			if (argv[arg_idx][1] == '-' && *p == 'm') ++p; // enable --moption to
			no = !strncmp(p, "no-", 3);
			if (no) p += 3;
			for (idx = 0; idx < sizeof(tostool_opts) / sizeof(tostool_opts[0]); ++idx) {
				if (!strcmp(p, tostool_opts[idx].option)) {
					if (no && (tostool_opts[idx].flags & OPTION_WITH_NO)) {
						tostool_argv[tostool_argc++] = argv[arg_idx];
						break;
					} else if (!no) {
						if (tostool_opts[idx].flags & OPTION_WITH_ARG)
							if((arg_idx + 1) < argc) tostool_argv[tostool_argc++] = argv[arg_idx++];
						tostool_argv[tostool_argc++] = argv[arg_idx];
						break;
					}
				}
			}
			if(idx == sizeof(tostool_opts) / sizeof(tostool_opts[0])) // no tostool opt -> ld
				ld_argv[ld_argc++] = argv[arg_idx];
		} else {
			ld_argv[ld_argc++] = argv[arg_idx];
		}


	}
	ld_argv[ld_argc++] = "-v";
	if (!ld_output_idx) { // no -o Filename -> use std "a.elf"
		ld_argv[ld_argc++] = "-o";
		ld_argv[ld_argc++] = tostool_input;
	} else {
		p = ld_argv[ld_output_idx];
		if(!strcmp(p, "-") || !strcmp(p, "/dev/null") || !strcmp(p, "nul")) {
			no_tostool = 1; // output to stdout or /dev/null -> don't invoke tostool
		} else {
			p = getFileExt(ld_argv[ld_output_idx]);
			if (p && !strcasecmp(p, ".elf"))
				no_tostool = 1; // explicit .elf -> don't invoke tostool
			else {
				tostool_output = ld_argv[ld_output_idx];

				if (!p) p = &tostool_output[strlen(tostool_output)];
				if (!(tostool_input = (char*)malloc(p - tostool_output + sizeof(".elf")))) fatal("out of memory@" LINE_STRING);
				strncpy(tostool_input, tostool_output, p - tostool_output); tostool_input[p - tostool_output] = 0;
				strcat(tostool_input, ".elf");

				ld_argv[ld_output_idx] = tostool_input;
			}
		}
	}

	if (!no_tostool) {
		tostool_argv[tostool_argc++] = tostool_input;
		tostool_argv[tostool_argc++] = tostool_output;
	}
	ld_argv[ld_argc] = tostool_argv[tostool_argc] = NULL;

	print_args("ld", ld_argc, ld_argv);
	print_args("tostool", tostool_argc, tostool_argv);

	if(vfork_exec(ld_argv, NULL)) return 1;
	if (!no_tostool) {
		print_args("tostool", tostool_argc, tostool_argv);
		if (vfork_exec(tostool_argv, NULL)) {
			if (!keep_elf) remove(tostool_input);
			return 1;
		} else {
			if (!keep_elf) remove(tostool_input);
			if(help) fprintf(stdout, "  --keep-elf                  don't remove the *.elf file\n");
		}
	}
	return 0;
}
