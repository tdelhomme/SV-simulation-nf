# SV-simulation-nf
Nextflow pipeline to simulate structural variations in long reads sequencing data

### Notes
The pipeline relies on [Sim-it](https://github.com/ndierckx/Sim-it) long read simulator.  
Please read the instructions of installation and dependencies.
Particularly, you will need the `Parallel::ForkManager` perl module. If you are not root (e.g. using a cluster), you can add the following lines in your `~/.profile` in order to get the module:

```
eval `perl -I ~/perl5/lib/perl5 -Mlocal::lib`
MANPATH=/home/tdelhomme/perl5/man
export MANPATH=$HOME/perl5/man:$MANPATH
```
