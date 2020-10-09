
class Device {
    constructor(data, name) {
        this.data = data;
        this.name = name;
    }

    get id() {
        return this.data.id;
    }

    get items() {
        if(!this.data.content) {
            return [];
        }
        return this.data.content.items || [];
    }

    get connectors() {
        if(!this.data.content) {
            return [];
        }
        return this.data.content.items || [];
    }
}

module.exports = Device;