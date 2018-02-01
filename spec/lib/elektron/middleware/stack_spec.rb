describe Elektron::Middlewares::Stack do
  class Middleware < Elektron::Middlewares::Base; end
  class Middleware1 < Middleware; end
  class Middleware2 < Middleware; end
  class Middleware3 < Middleware; end
  class Middleware4 < Middleware; end
  class Middleware10 < Middleware; end

  before :each do
    @middlewares = Elektron::Middlewares::Stack.new
  end

  describe '#add' do
    it 'should responsd to add' do
      expect(@middlewares).to respond_to(:add).with(1).arguments
    end

    it 'should accept after and before options' do
      expect(@middlewares).to respond_to(
        :add
      ).with(1).argument.and_keywords(:after, :before)
    end

    it 'should raise error if middleware does not respond to call method' do
      expect do
        @middlewares.add('NotAMiddleware')
      end.to raise_error(Elektron::Middlewares::Stack::BadMiddlewareError)
    end

    it 'should add a middleware to middlewares' do
      expect do
        @middlewares.add(Middleware1)
      end.to change(@middlewares.all, :length).by(1)
    end

    context 'middleware order' do
      before :each do
        @middlewares.add(Middleware1)
        @middlewares.add(Middleware2)
        @middlewares.add(Middleware3)
      end

      it 'should return 3' do
        expect(@middlewares.all.length).to eq(3)
      end

      it 'should return ordered list' do
        expect(@middlewares.all).to eq(
          [Middleware1, Middleware2, Middleware3]
        )
      end

      it 'should add Middleware4 after Middleware1' do
        @middlewares.add(Middleware4, after: Middleware2)
        expect(@middlewares.all).to eq(
          [Middleware1, Middleware2, Middleware4, Middleware3]
        )
      end

      it 'should add Middleware4 before Middleware2' do
        @middlewares.add(Middleware4, before: Middleware2)
        expect(@middlewares.all).to eq(
          [Middleware1, Middleware4, Middleware2, Middleware3]
        )
      end

      it 'should add Middleware4 at the end' do
        @middlewares.add(Middleware4, after: Middleware1)
        expect(@middlewares.all).to eq(
          [Middleware1, Middleware4, Middleware2, Middleware3]
        )
      end

      it 'should add Middleware4 at the start' do
        @middlewares.add(Middleware4, before: Middleware1)
        expect(@middlewares.all).to eq(
          [Middleware4, Middleware1, Middleware2, Middleware3]
        )
      end

      it 'should add Middleware4 at the start if before does not exist' do
        @middlewares.add(Middleware4, before: Middleware10)
        expect(@middlewares.all).to eq(
          [Middleware1, Middleware2, Middleware3, Middleware4]
        )
      end

      it 'should add Middleware4 at the start with bad after parameter' do
        @middlewares.add(Middleware4, after: Middleware10)
        expect(@middlewares.all).to eq(
          [Middleware1, Middleware2, Middleware3, Middleware4]
        )
      end
    end
  end

  describe '#remove' do
    before :each do
      @middlewares.add(Middleware1)
      @middlewares.add(Middleware4)
      @middlewares.add(Middleware2)
      @middlewares.add(Middleware3)
    end

    it 'should responsd to remove' do
      expect(@middlewares).to respond_to(:remove).with(1).arguments
    end

    it 'should remove Middleware4' do
      @middlewares.remove(Middleware4)
      expect(@middlewares.all).to eq(
        [Middleware1, Middleware2, Middleware3]
      )
    end
  end

  describe '#replace' do
    before :each do
      @middlewares.add(Middleware1)
      @middlewares.add(Middleware2)
      @middlewares.add(Middleware3)
    end

    it 'should responsd to replace' do
      expect(@middlewares).to respond_to(:replace).with(2).arguments
    end

    it 'should replace Middleware1 with Middleware4' do
      @middlewares.replace(Middleware1, Middleware4)
      expect(@middlewares.all).to eq(
        [Middleware4, Middleware2, Middleware3]
      )
    end

    it 'should replace Middleware2 with Middleware4' do
      @middlewares.replace(Middleware2, Middleware4)
      expect(@middlewares.all).to eq(
        [Middleware1, Middleware4, Middleware3]
      )
    end
  end

  describe '#to_s' do
    before :each do
      @middlewares.add(Middleware1)
      @middlewares.add(Middleware4)
      @middlewares.add(Middleware2)
      @middlewares.add(Middleware3)
    end

    it 'should print the list of middlewares' do
      expect(@middlewares.to_s).to eq('Request <- Middleware1 <- Middleware4 <- Middleware2 <- Middleware3')
    end
  end

  describe '#all' do
    it 'should respond to middlewares' do
      expect(@middlewares).to respond_to(:all).with(0).arguments
    end

    it 'should return an empty array' do
      expect(@middlewares.all).to eq([])
    end

    it 'should return non empty array' do
      expect do
        @middlewares.add(Middleware1)
        @middlewares.add(Middleware2)
      end.to change(@middlewares.all, :length).by(2)
    end
  end

  describe '#execute_middlewares' do
    before :each do
      @middlewares.add(Middleware1)
      @middlewares.add(Middleware4)
      @middlewares.add(Middleware2)
      @middlewares.add(Middleware3)
    end

    it 'should initialize all middlewares in the correct order' do
      expect(Middleware1).to receive(:new).ordered.and_call_original
      expect(Middleware4).to receive(:new).ordered.and_call_original
      expect(Middleware2).to receive(:new).ordered.and_call_original
      expect(Middleware3).to receive(:new).ordered.and_call_original

      @middlewares.execute(double('request_context').as_null_object)
    end

    it 'should call all middlewares in the correct order' do
      expect_any_instance_of(Middleware3).to receive(:call).and_call_original
      expect_any_instance_of(Middleware2).to receive(:call).and_call_original
      expect_any_instance_of(Middleware4).to receive(:call).and_call_original
      expect_any_instance_of(Middleware1).to receive(:call).and_call_original

      @middlewares.execute(double('request_context').as_null_object)
    end
  end
end
