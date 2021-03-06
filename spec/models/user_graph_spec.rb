require 'rails_helper'

RSpec.describe UserGraph, type: :model do
  let(:user1) { Fabricate(:user) }
  let(:user2) { Fabricate(:user) }
  let(:user3) { Fabricate(:user) }

  before do
    [user1, user2, user3].each_with_index { |u, i| u.update!(subscription: Fabricate(:subscription, plan: Fabricate(:plan, name: "plan-#{i}"))) }
  end

  context 'chain-type graph' do
    before do
      create_edge(user1, user2)
      create_edge(user2, user3)
    end

    describe 'FriendsBuilder#build' do
      subject { UserGraph::FriendsBuilder.new(user: user1).build }

      it { expect(subject).to be_instance_of UserGraph::Graph }
      it { expect(subject.center).to be user1 }
      it { expect(subject.nodes).to include user1, user2, user3 }
      it { expect(subject.edges).to include [user1.id, user2.id, 1], [user2.id, user1.id, 1], [user2.id, user3.id, 1], [user3.id, user2.id, 1] }
      it { expect(subject.to_json).to be_instance_of String }
    end
  end

  context 'cyclic graph' do
    before do
      create_edge(user1, user2)
      create_edge(user2, user3)
      create_edge(user3, user1)
    end

    describe 'FriendsBuilder#build' do
      subject { UserGraph::FriendsBuilder.new(user: user1).build }

      it { expect(subject).to be_instance_of UserGraph::Graph }
      it { expect(subject.center).to be user1 }
      it { expect(subject.nodes).to include user1, user2, user3 }
      it { expect(subject.edges).to include [user1.id, user2.id, 1], [user1.id, user3.id, 1], [user2.id, user1.id, 1], [user2.id, user3.id, 1], [user3.id, user2.id, 1], [user3.id, user1.id, 1] }
      it { expect(subject.to_json).to be_instance_of String }
    end
  end

  describe 'FullBuilder#build' do
    subject { UserGraph::FullBuilder.new.build }

    it { expect(subject).to be_instance_of UserGraph::Graph }
  end

  describe 'AccessBuilder#build' do
    subject { UserGraph::AccessBuilder.new.build }

    it { expect(subject).to be_instance_of UserGraph::Graph }
  end

  def create_edge(a, b)
    FriendEdge.create(from: a, to: b, network: 'foo')
    FriendEdge.create(from: b, to: a, network: 'foo')
  end
end
