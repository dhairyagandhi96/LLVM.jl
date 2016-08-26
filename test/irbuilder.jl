let
    builder = Builder()
    dispose(builder)
end

Builder() do builder
end

Context() do ctx
Builder(ctx) do builder
LLVMModule("SomeModule", ctx) do mod    
    ft = LLVM.FunctionType(LLVM.VoidType(), [LLVM.Int32Type()])
    fn = LLVMFunction(mod, "SomeFunction", ft)

    entry = BasicBlock(fn, "entry")
    position!(builder, entry)
    @assert position(builder) == entry

    loc = debuglocation(builder)
    md = MDNode([MDString("SomeMDString", ctx)], ctx)
    debuglocation!(builder, md)
    @test debuglocation(builder) == md
    debuglocation!(builder)
    @test debuglocation(builder) == loc

    retinst = ret!(builder, ConstantInt(LLVM.Int32Type(), 0))
    debuglocation!(builder, retinst)

    position!(builder, retinst)
    unrinst = unreachable!(builder)
    @test collect(instructions(entry)) == [unrinst, retinst]

    unsafe_delete!(entry, retinst)
    @test collect(instructions(entry)) == [unrinst]
    position!(builder, entry)
    retinst = ret!(builder)
    @test collect(instructions(entry)) == [unrinst, retinst]

    position!(builder, retinst)
    addinst = add!(builder, parameters(fn)[1],
                   ConstantInt(LLVM.Int32Type(), 1), "SomeAddition")
    @test collect(instructions(entry)) == [unrinst, addinst, retinst]
    retinst2 = Instruction(retinst)
    insert!(builder, retinst2)
    @test collect(instructions(entry)) == [unrinst, addinst, retinst2, retinst]

    position!(builder)
end
end
end
