typedef enum {CLKON,CLKOFF,RESET,WRREG,RDREG} phy_cmd_t;
typedef enum {FREQ_LOW_TRANS,FREQ_MED_TRANS,FREQ_HIGH_TRANS} layer_cmd_t;

class bus_trans extends uvm_sequence_item;                  //bus_trans是底层的transaction
    rand int addr;
    rand int data;
    rand phy_cmd_t cmd;
    constraint cstr{
        soft addr == 'h0;
        soft data == 'h0;
    }
endclass

class packet_seq extends uvm_sequence;                      //packet_seq去包含去生成这个bus_trans
    rand int len;
    rand int addr;
    rand int data{};
    rand phy_cmd_t cmd;
    constraint cstr{
        soft len inside{30:50};
        soft addr[31:16] == 'hFF00;
        data.size() == len;
    }

    task body();
        bus_trans req;
        foreach(data[i])
            `uvm_do_with(req,{cmd == local::cmd;
                              addr == local::addr;
                              data == local::data[i];})
    endtask
endclass

class layer_trans extends uvm_sequence_item;                //layer_trans和bus_trans没任何关系，也没任何的继承关系，所以高抽象和底抽象之间要做一个映射
    rand int pkt_len;
    rand int pkt_idel;
    rand layer_cmd_t layer_cmd;
    constraint cstr{
        soft pkt_len inside {[10:20]};
        layer_cmd == FREQ_LOW_TRANS -> pkt_idel inside {[300:400]};
        layer_cmd == FREQ_MED_TRANS -> pkt_idel inside {[100:200]};
        layer_cmd == FREQ_HIGH_TRANS -> pkt_idel inside {[20:40]};
    }
endclass

class adapter_seq extends uvm_sequence;
    `uvm_object_utils(adapter_seq)
    `uvm_declare_p_sequencer(phy_master_sequencer)

    task body();
        layer_trans trans;
        packet_seq  pkt;
        forever begin
            p_sequencer.up_sqr.get_next_item(req);
            void'($cast(trans,req));
            repeat(trans.pkt_len) begin
                `uvm_do(pkt)
                delay(trans.pkt_idel);
            end
            p_sequencer.up_sqr.item_done();
        end
    endtask

    virtual task delay(int delay);

    endtask
endclass

class top_seq extends uvm_sequence;

    task body();
        layer_trans trans;
        `uvm_do_with(trans,{layer_cmd == FREQ_LOW_TRANS;})
        `uvm_do_with(trans,{layer_cmd == FREQ_HIGH_TRANS;})
    endtask

endclass

class layering_sequencer extends uvm_sequencer;
    ......
endclass

class phy_master_sequencer extends uvm_sequencer;
    layering_sequencer up_sqr;
    ......
endclass

class phy_master_driver extends uvm_driver;
    ......
    task run_phase(uvm_phase phase);
    REQ tmp;
    bus_trans   req;
    forever begin
        seq_item_port.get_next_item(tmp);
        void'($cast(req,tmp));
        `uvm_info("DRV",$sformatf("got a item \n %s",req.sprint()),UVM_LOW)
        seq_item_port.item_done();
    end
    endtask
endclass

class phy_master_agent extends uvm_agent;
    phy_master_sequencer    sqr;
    phy_master_driver       drv;

    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
        sqr = phy_master_sequencer::type_id::create("sqr",this);
        drv = phy_master_driver::type_id::create("drv",this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connet(sqr.seq_item_export);
    endfunction
endclass

class test1 extends uvm_test;
    `uvm_object_utils(test1)


endclass



