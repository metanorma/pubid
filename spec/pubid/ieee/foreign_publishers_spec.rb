# frozen_string_literal: true

require "spec_helper"

# Foreign / partner co-publishers seen in relaton-data-ieee that pubid did not
# recognize (bucket 4): AMPP and USAS (standalone), and the IEEE sub-board /
# partner co-publishers USEMCSC, EAB, MPAI. Adding them to the `organization`
# rule lets these rows parse with a non-empty root.number and round-trip.
# (hand-off: ieee-numberless-standard-parse roadmap, bucket 4.)
RSpec.describe "IEEE foreign/partner publishers" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # ref => bare root.number
  {
    "AMPP SP21496-2023" => "P21496",
    "ANSI/USEMCSC C63.14-2023" => "63",
    "ANSI/USEMCSC C63.10/Cor1-2023" => "63",
    "IEEE/EAB 1100" => "1100",
    "IEEE/MPAI P3302/D-1-2024-06" => "3302",
    "USAS C57.12.00-1968" => "57",
  }.each do |ref, number|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "exposes a non-empty root.number" do
        expect(id.root.number).to eq(number)
      end

      it "round-trips through to_hash/from_hash (the relaton index gate)" do
        h = id.to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end
    end
  end
end
