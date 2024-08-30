// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 15.04.2017
// Description: Instruction decode, contains the logic for decode,
//              issue and read operands.

module id_stage #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type branchpredict_sbe_t = logic,
    parameter type exception_t = logic,
    parameter type fetch_entry_t = logic,
    parameter type irq_ctrl_t = logic,
    parameter type scoreboard_entry_t = logic,
    parameter type interrupts_t = logic,
    parameter interrupts_t INTERRUPTS = '0
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Fetch flush request - CONTROLLER
    input logic flush_i,
    // Debug (async) request - SUBSYSTEM
    input logic debug_req_i,
    // Handshake's data between fetch and decode - FRONTEND
    input fetch_entry_t [ariane_pkg::SUPERSCALAR:0] fetch_entry_i,
    // Handshake's valid between fetch and decode - FRONTEND
    input logic [ariane_pkg::SUPERSCALAR:0] fetch_entry_valid_i,
    // Handshake's ready between fetch and decode - FRONTEND
    output logic [ariane_pkg::SUPERSCALAR:0] fetch_entry_ready_o,
    // Handshake's data between decode and issue - ISSUE
    output scoreboard_entry_t [ariane_pkg::SUPERSCALAR:0] issue_entry_o,
    // Instruction value - ISSUE
    output logic [ariane_pkg::SUPERSCALAR:0][31:0] orig_instr_o,
    // Handshake's valid between decode and issue - ISSUE
    output logic [ariane_pkg::SUPERSCALAR:0] issue_entry_valid_o,
    // Report if instruction is a control flow instruction - ISSUE
    output logic [ariane_pkg::SUPERSCALAR:0] is_ctrl_flow_o,
    // Handshake's acknowlege between decode and issue - ISSUE
    input logic [ariane_pkg::SUPERSCALAR:0] issue_instr_ack_i,
    // Information dedicated to RVFI - RVFI
    output logic [ariane_pkg::SUPERSCALAR:0] rvfi_is_compressed_o,
    // Current privilege level - CSR_REGFILE
    input riscv::priv_lvl_t priv_lvl_i,
    // Current virtualization mode - CSR_REGFILE
    input logic v_i,
    // Floating point extension status - CSR_REGFILE
    input riscv::xs_t fs_i,
    // Floating point extension virtual status - CSR_REGFILE
    input riscv::xs_t vfs_i,
    // Floating point dynamic rounding mode - CSR_REGFILE
    input logic [2:0] frm_i,
    // Vector extension status - CSR_REGFILE
    input riscv::xs_t vs_i,
    // Level sensitive (async) interrupts - SUBSYSTEM
    input logic [1:0] irq_i,
    // Interrupt control status - CSR_REGFILE
    input irq_ctrl_t irq_ctrl_i,
    // Is current mode debug ? - CSR_REGFILE
    input logic debug_mode_i,
    // Trap virtual memory - CSR_REGFILE
    input logic tvm_i,
    // Timeout wait - CSR_REGFILE
    input logic tw_i,
    // Virtual timeout wait - CSR_REGFILE
    input logic vtw_i,
    // Trap sret - CSR_REGFILE
    input logic tsr_i,
    // Hypervisor user mode - CSR_REGFILE
    input logic hu_i
);
  // ID/ISSUE register stage
  typedef struct packed {
    logic              valid;
    scoreboard_entry_t sbe;
    logic [31:0]       orig_instr;
    logic              is_ctrl_flow;
  } issue_struct_t;
  issue_struct_t [ariane_pkg::SUPERSCALAR:0] issue_n, issue_q;

  logic              [ariane_pkg::SUPERSCALAR:0]       is_control_flow_instr;
  scoreboard_entry_t [ariane_pkg::SUPERSCALAR:0]       decoded_instruction;
  logic              [ariane_pkg::SUPERSCALAR:0][31:0] orig_instr;

  logic              [ariane_pkg::SUPERSCALAR:0]       is_illegal;
  logic              [ariane_pkg::SUPERSCALAR:0]       is_illegal_cmp;
  logic              [ariane_pkg::SUPERSCALAR:0][31:0] instruction;
  logic              [ariane_pkg::SUPERSCALAR:0][31:0] compressed_instr;
  logic              [ariane_pkg::SUPERSCALAR:0]       is_compressed;
  logic              [ariane_pkg::SUPERSCALAR:0]       is_compressed_cmp;
  logic              [ariane_pkg::SUPERSCALAR:0]       is_macro_instr_i;
  logic                                                stall_instr_fetch;
  logic                                                is_last_macro_instr_o;
  logic                                                is_double_rd_macro_instr_o;

  if (CVA6Cfg.RVC) begin
    // ---------------------------------------------------------
    // 1. Check if they are compressed and expand in case they are
    // ---------------------------------------------------------
    for (genvar i = 0; i <= ariane_pkg::SUPERSCALAR; i++) begin
      compressed_decoder #(
          .CVA6Cfg(CVA6Cfg)
      ) compressed_decoder_i (
          .instr_i         (fetch_entry_i[i].instruction),
          .instr_o         (compressed_instr[i]),
          .illegal_instr_o (is_illegal[i]),
          .is_compressed_o (is_compressed[i]),
          .is_macro_instr_o(is_macro_instr_i[i])
      );
    end
    if (CVA6Cfg.RVZCMP) begin
      //sequencial decoder
      macro_decoder #(
          .CVA6Cfg(CVA6Cfg)
      ) macro_decoder_i (
          .instr_i                   (compressed_instr[0]),
          .is_macro_instr_i          (is_macro_instr_i[0]),
          .clk_i                     (clk_i),
          .rst_ni                    (rst_ni),
          .instr_o                   (instruction[0]),
          .illegal_instr_i           (is_illegal[0]),
          .is_compressed_i           (is_compressed[0]),
          .issue_ack_i               (issue_instr_ack_i[0]),
          .illegal_instr_o           (is_illegal_cmp[0]),
          .is_compressed_o           (is_compressed_cmp[0]),
          .fetch_stall_o             (stall_instr_fetch),
          .is_last_macro_instr_o     (is_last_macro_instr_o),
          .is_double_rd_macro_instr_o(is_double_rd_macro_instr_o)
      );
      if (ariane_pkg::SUPERSCALAR > 0) begin
        assign instruction[ariane_pkg::SUPERSCALAR] = '0;
        assign is_illegal_cmp[ariane_pkg::SUPERSCALAR] = '0;
        assign is_compressed_cmp[ariane_pkg::SUPERSCALAR] = '0;
      end
    end else begin
      assign instruction = compressed_instr;
      assign is_illegal_cmp = is_illegal;
      assign is_compressed_cmp = is_compressed;
      assign is_last_macro_instr_o = '0;
      assign is_double_rd_macro_instr_o = '0;
    end
  end else begin
    for (genvar i = 0; i <= ariane_pkg::SUPERSCALAR; i++) begin
      assign instruction[i] = fetch_entry_i[i].instruction;
    end
    assign is_illegal_cmp = '0;
    assign is_compressed_cmp = '0;
    assign is_macro_instr_i = '0;
    assign is_last_macro_instr_o = '0;
    assign is_double_rd_macro_instr_o = '0;
  end

  assign rvfi_is_compressed_o = is_compressed_cmp;
  // ---------------------------------------------------------
  // 2. Decode and emit instruction to issue stage
  // ---------------------------------------------------------
  for (genvar i = 0; i <= ariane_pkg::SUPERSCALAR; i++) begin
    decoder #(
        .CVA6Cfg(CVA6Cfg),
        .branchpredict_sbe_t(branchpredict_sbe_t),
        .exception_t(exception_t),
        .irq_ctrl_t(irq_ctrl_t),
        .scoreboard_entry_t(scoreboard_entry_t),
        .interrupts_t(interrupts_t),
        .INTERRUPTS(INTERRUPTS)
    ) decoder_i (
        .debug_req_i,
        .irq_ctrl_i,
        .irq_i,
        .pc_i                      (fetch_entry_i[i].address),
        .is_compressed_i           (is_compressed_cmp[i]),
        .is_macro_instr_i          (is_macro_instr_i[i]),
        .is_last_macro_instr_i     (is_last_macro_instr_o),
        .is_double_rd_macro_instr_i(is_double_rd_macro_instr_o),
        .is_illegal_i              (is_illegal_cmp[i]),
        .instruction_i             (instruction[i]),
        .compressed_instr_i        (fetch_entry_i[i].instruction[15:0]),
        .branch_predict_i          (fetch_entry_i[i].branch_predict),
        .ex_i                      (fetch_entry_i[i].ex),
        .priv_lvl_i                (priv_lvl_i),
        .v_i                       (v_i),
        .debug_mode_i              (debug_mode_i),
        .fs_i,
        .vfs_i,
        .frm_i,
        .vs_i,
        .tvm_i,
        .tw_i,
        .vtw_i,
        .tsr_i,
        .hu_i,
        .instruction_o             (decoded_instruction[i]),
        .orig_instr_o              (orig_instr[i]),
        .is_control_flow_instr_o   (is_control_flow_instr[i])
    );
  end

  // ------------------
  // Pipeline Register
  // ------------------
  for (genvar i = 0; i <= ariane_pkg::SUPERSCALAR; i++) begin
    assign issue_entry_o[i] = issue_q[i].sbe;
    assign issue_entry_valid_o[i] = issue_q[i].valid;
    assign is_ctrl_flow_o[i] = issue_q[i].is_ctrl_flow;
    assign orig_instr_o[i] = issue_q[i].orig_instr;
  end

  if (ariane_pkg::SUPERSCALAR) begin
    always_comb begin
      issue_n = issue_q;
      fetch_entry_ready_o = '0;

      // Clear the valid flag if issue has acknowledged the instruction
      if (issue_instr_ack_i[0]) begin
        issue_n[0].valid = 1'b0;
      end
      if (issue_instr_ack_i[1]) begin
        issue_n[1].valid = 1'b0;
      end

      if (!issue_n[0].valid) begin
        if (issue_n[1].valid) begin
          issue_n[0] = issue_n[1];
          issue_n[1].valid = 1'b0;
        end else if (fetch_entry_valid_i[0]) begin
          fetch_entry_ready_o[0] = 1'b1;
          issue_n[0] = '{1'b1, decoded_instruction[0], orig_instr[0], is_control_flow_instr[0]};
        end
      end

      if (!issue_n[1].valid) begin
        if (fetch_entry_ready_o[0]) begin
          if (fetch_entry_valid_i[1]) begin
            fetch_entry_ready_o[1] = 1'b1;
            issue_n[1] = '{1'b1, decoded_instruction[1], orig_instr[1], is_control_flow_instr[1]};
          end
        end else if (fetch_entry_valid_i[0]) begin
          fetch_entry_ready_o[0] = 1'b1;
          issue_n[1] = '{1'b1, decoded_instruction[0], orig_instr[0], is_control_flow_instr[0]};
        end
      end

      if (flush_i) begin
        issue_n[0].valid = 1'b0;
        issue_n[1].valid = 1'b0;
      end
    end
  end else begin
    always_comb begin
      issue_n             = issue_q;
      fetch_entry_ready_o = '0;

      // Clear the valid flag if issue has acknowledged the instruction
      if (issue_instr_ack_i[0]) issue_n[0].valid = 1'b0;

      // if we have a space in the register and the fetch is valid, go get it
      // or the issue stage is currently acknowledging an instruction, which means that we will have space
      // for a new instruction
      if ((!issue_q[0].valid || issue_instr_ack_i[0]) && fetch_entry_valid_i[0]) begin
        if (stall_instr_fetch) begin
          fetch_entry_ready_o[0] = 1'b0;
        end else begin
          fetch_entry_ready_o[0] = 1'b1;
        end
        issue_n[0] = '{1'b1, decoded_instruction[0], orig_instr[0], is_control_flow_instr[0]};
      end

      // invalidate the pipeline register on a flush
      if (flush_i) issue_n[0].valid = 1'b0;
    end
  end
  // -------------------------
  // Registers (ID <-> Issue)
  // -------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      issue_q <= '0;
    end else begin
      issue_q <= issue_n;
    end
  end
endmodule
