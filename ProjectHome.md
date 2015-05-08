A m68k ATARI MiNT Cross Compiling Environment with ELF-based Objectfiles.

---

The advantage of the ELF format is the support of named sections.

This helps to shrink code particularly in C++. C++ generates implizit some code stuff. E.G. VMT's (virtual method table), template implementation and so on. All this code can generated in different object-files. But this code is always the same.<br>
<ul><li><b>Normally</b> this code is "static" and is included in all object-files that references to this code.<br>
</li><li><b>If weak-symbols</b> is supported, then this code is weaked and all references points to the same code-adress. But the code is still included in all object-files that references to this code.<br>
</li><li><b>If named-sections</b> is supported, then this code is stored in a own section ".gnu.linkonce.<code>*</code>". This section will be linked only one time.</li></ul>

<h2>m68k-atari-mint-elf extensions</h2>
<ul><li>option -cmini (for linking with libcmini instead libc)<br>
</li><li>function attribute <code>__</code>attribute<code>__</code>((slb_export(slot_nr))) (see slb-support)<br>
</li><li>function attribute <code>__</code>attribute<code>__</code>((mshort_call)) function use argument boundary of 16 instead 32 bit (like compiled with -mshort).