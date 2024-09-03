/*
 *  Copyright 2023 CEA*
 *  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the “License”); you
 *  may not use this file except in compliance with the License, or, at your
 *  option, the Apache License version 2.0. You may obtain a copy of the
 *  License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */
/*
 *  Authors       : Cesar Fuguet
 *  Creation Date : July, 2021
 *  Description   : HPDcache Cache-Management-Operation Handler
 *  History       :
 */
module hpdcache_cmo
import hpdcache_pkg::*;
//  Parameters
//  {{{
#(
    parameter hpdcache_cfg_t HPDcacheCfg = '0,

    parameter type hpdcache_nline_t = logic,
    parameter type hpdcache_tag_t = logic,
    parameter type hpdcache_set_t = logic,
    parameter type hpdcache_data_word_t = logic,
    parameter type hpdcache_way_vector_t = logic,

    parameter type hpdcache_req_addr_t = logic,
    parameter type hpdcache_req_data_t = logic
)
//  }}}

//  Ports
//  {{{
(
    input  logic                  clk_i,
    input  logic                  rst_ni,

    //  Global control signals
    //  {{{
    input  logic                  wbuf_empty_i,
    input  logic                  mshr_empty_i,
    input  logic                  rtab_empty_i,
    input  logic                  ctrl_empty_i,
    //  }}}

    //  Request interface
    //  {{{
    input  logic                  req_valid_i,
    output logic                  req_ready_o,
    input  hpdcache_cmoh_op_t     req_op_i,
    input  hpdcache_req_addr_t    req_addr_i,
    input  hpdcache_req_data_t    req_wdata_i,
    output logic                  req_wait_o,
    //  }}}

    //  Write Buffer Interface
    //  {{{
    output logic                  wbuf_flush_all_o,
    //  }}}

    //  Cache Directory Interface
    //  {{{
    output logic                  dir_check_o,
    output hpdcache_set_t         dir_check_set_o,
    output hpdcache_tag_t         dir_check_tag_o,
    input  hpdcache_way_vector_t  dir_check_hit_way_i,

    output logic                  dir_inval_o,
    output hpdcache_set_t         dir_inval_set_o,
    output hpdcache_way_vector_t  dir_inval_way_o
    // }}}
);
//  }}}

//  Definition of constants and types
//  {{{
    typedef enum {
        CMOH_IDLE,
        CMOH_FENCE_WAIT_WBUF_RTAB_EMPTY,
        CMOH_INVAL_WAIT_MSHR_RTAB_EMPTY,
        CMOH_INVAL_CHECK_NLINE,
        CMOH_INVAL_SET
    } hpdcache_cmoh_fsm_t;
//  }}}

//  Internal signals and registers
//  {{{
    hpdcache_cmoh_fsm_t   cmoh_fsm_q, cmoh_fsm_d;
    hpdcache_cmoh_op_t    cmoh_op_q, cmoh_op_d;
    hpdcache_req_addr_t   cmoh_addr_q, cmoh_addr_d;
    hpdcache_way_vector_t cmoh_way_q, cmoh_way_d;
    hpdcache_set_t        cmoh_set_cnt_q, cmoh_set_cnt_d;
    hpdcache_nline_t      cmoh_nline_q;
    hpdcache_tag_t        cmoh_tag_q;
    hpdcache_set_t        cmoh_set_q;
    hpdcache_data_word_t  cmoh_wdata;
//  }}}

//  CMO request handler FSM
//  {{{
    assign cmoh_nline_q =  cmoh_addr_q[HPDcacheCfg.clOffsetWidth +: HPDcacheCfg.nlineWidth],
           cmoh_set_q   = cmoh_nline_q[0                         +: HPDcacheCfg.setWidth],
           cmoh_tag_q   = cmoh_nline_q[HPDcacheCfg.setWidth      +: HPDcacheCfg.tagWidth];

    assign dir_check_set_o = cmoh_set_q,
           dir_check_tag_o = cmoh_tag_q;

    assign req_ready_o  = (cmoh_fsm_q == CMOH_IDLE),
           req_wait_o   = (cmoh_fsm_q == CMOH_FENCE_WAIT_WBUF_RTAB_EMPTY) |
                          (cmoh_fsm_q == CMOH_INVAL_WAIT_MSHR_RTAB_EMPTY);

    //  Only the least significant word of the write data contains parameters
    //  for the CMO handler
    assign cmoh_wdata   = req_wdata_i[0];

    always_comb
    begin : cmoh_fsm_comb
        cmoh_op_d        = cmoh_op_q;
        cmoh_addr_d      = cmoh_addr_q;
        cmoh_way_d       = cmoh_way_q;
        cmoh_set_cnt_d   = cmoh_set_cnt_q;

        dir_check_o      = 1'b0;
        dir_inval_o      = 1'b0;
        dir_inval_set_o  = cmoh_set_q;
        dir_inval_way_o  = '0;

        wbuf_flush_all_o = 1'b0;

        cmoh_fsm_d       = cmoh_fsm_q;

        unique case (cmoh_fsm_q)
            CMOH_IDLE: begin
                cmoh_fsm_d  = CMOH_IDLE;

                if (req_valid_i) begin
                    unique case (1'b1)
                        req_op_i.is_fence: begin
                            //  request to the write buffer to send all open entries
                            wbuf_flush_all_o = rtab_empty_i;

                            //  then wait for the write buffer to be empty
                            if (!rtab_empty_i || !wbuf_empty_i) begin
                                cmoh_fsm_d = CMOH_FENCE_WAIT_WBUF_RTAB_EMPTY;
                            end
                        end
                        req_op_i.is_inval_by_nline,
                        req_op_i.is_inval_by_set,
                        req_op_i.is_inval_all: begin
                            cmoh_op_d      = req_op_i;
                            cmoh_addr_d    = req_addr_i;
                            cmoh_way_d     = cmoh_wdata[0 +: HPDcacheCfg.u.ways];
                            cmoh_set_cnt_d = 0;
                            if (mshr_empty_i && rtab_empty_i && ctrl_empty_i) begin // CMO
                                if (req_op_i.is_inval_by_nline) begin
                                    cmoh_fsm_d = CMOH_INVAL_CHECK_NLINE;
                                end else begin
                                    cmoh_fsm_d = CMOH_INVAL_SET;
                                end
                            end else begin
                                cmoh_fsm_d = CMOH_INVAL_WAIT_MSHR_RTAB_EMPTY;
                            end
                        end
                    endcase
                end
            end
            CMOH_FENCE_WAIT_WBUF_RTAB_EMPTY: begin
                wbuf_flush_all_o = rtab_empty_i;
                if (wbuf_empty_i && rtab_empty_i) begin
                    cmoh_fsm_d = CMOH_IDLE;
                end else begin
                    cmoh_fsm_d = CMOH_FENCE_WAIT_WBUF_RTAB_EMPTY;
                end
            end
            CMOH_INVAL_WAIT_MSHR_RTAB_EMPTY: begin
                cmoh_fsm_d = CMOH_INVAL_WAIT_MSHR_RTAB_EMPTY;
                if (mshr_empty_i && rtab_empty_i && ctrl_empty_i) begin
                    if (cmoh_op_q.is_inval_by_nline) begin
                        cmoh_fsm_d = CMOH_INVAL_CHECK_NLINE;
                    end else begin
                        cmoh_fsm_d = CMOH_INVAL_SET;
                    end
                end
            end
            CMOH_INVAL_CHECK_NLINE: begin
                dir_check_o = 1'b1;
                cmoh_fsm_d  = CMOH_INVAL_SET;
            end
            CMOH_INVAL_SET: begin
                cmoh_fsm_d = CMOH_INVAL_SET;
                unique case (1'b1)
                    cmoh_op_q.is_inval_by_nline: begin
                        dir_inval_o     = |dir_check_hit_way_i;
                        dir_inval_way_o =  dir_check_hit_way_i;
                        cmoh_fsm_d      = CMOH_IDLE;
                    end
                    cmoh_op_q.is_inval_all: begin
                        dir_inval_o     = 1'b1;
                        dir_inval_way_o = {HPDcacheCfg.u.ways{1'b1}};
                        dir_inval_set_o = cmoh_set_cnt_q;
                        cmoh_set_cnt_d  = cmoh_set_cnt_q + 1;
                        if (cmoh_set_cnt_q == hpdcache_set_t'(HPDcacheCfg.u.sets - 1)) begin
                            cmoh_fsm_d = CMOH_IDLE;
                        end
                    end
                    cmoh_op_q.is_inval_by_set: begin
                        dir_inval_o     = 1'b1;
                        dir_inval_way_o = cmoh_way_q;
                        cmoh_fsm_d      = CMOH_IDLE;
                    end
                endcase
            end
        endcase
    end
//  }}}

//  CMO request handler set state
//  {{{
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if (!rst_ni) begin
            cmoh_fsm_q <= CMOH_IDLE;
        end else begin
            cmoh_fsm_q <= cmoh_fsm_d;
        end
    end

    always_ff @(posedge clk_i)
    begin
        cmoh_op_q      <= cmoh_op_d;
        cmoh_addr_q    <= cmoh_addr_d;
        cmoh_way_q     <= cmoh_way_d;
        cmoh_set_cnt_q <= cmoh_set_cnt_d;
    end
//  }}}

//  Assertions
//  {{{
`ifndef HPDCACHE_ASSERT_OFF
    assert property (@(posedge clk_i) disable iff (!rst_ni)
            req_valid_i -> $onehot({req_op_i.is_fence,
                                    req_op_i.is_inval_by_nline,
                                    req_op_i.is_inval_by_set,
                                    req_op_i.is_inval_all})) else
                    $error("cmo_handler: invalid request");

    assert property (@(posedge clk_i) disable iff (!rst_ni)
            req_valid_i -> (cmoh_fsm_q == CMOH_IDLE)) else
                    $error("cmo_handler: new request received while busy");
`endif
//  }}}

endmodule
