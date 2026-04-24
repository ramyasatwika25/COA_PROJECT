module address_decoder(
    input  [7:0] address,
    output [5:0] tag,
    output [1:0] index
);

    assign index = address[1:0];
    assign tag   = address[7:2];

endmodule