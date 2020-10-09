
class Project {

    constructor(id) {
        this.id = id;
        this.topos = [];
        this.devs = [];
        this.prots = [];
        this.xtra = {};
        this.libs = [];
        this.runs = null;
        this.runtree = null;
    }

    push_topo(name, topo) {
        this.topos.push([name, topo]);
    }
    
    push_prot(name, prot) {
        this.prots.push([name, prot]);
    }

    push_dev(name, dev) {
        this.devs.push([name, dev]);
    }

    push_lib(name, lib) {
        this.libs.push([name, lib]);
    }

    set_runtree(tree) {
        this.runtree = tree;
    }

    set_runs(runs) {
        this.runs = runs;
    }
}

module.exports = Project;