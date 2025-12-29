import React from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Button } from '../../components/common/Button';
import { Card, CardBody, CardHeader } from '../../components/common/Card';
import { GenerateStoryForm } from '../../components/stories/GenerateStoryForm';

export const GenerateStoryPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const childIdFromParams = searchParams.get('childId');
  const parentIdFromParams = searchParams.get('parentId');

  return (
    <div className="min-h-screen bg-[#F5F5F5]">
      <div className="max-w-4xl mx-auto px-8 py-8">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-semibold text-neutral-900 mb-2">Generate Story</h1>
            <p className="text-neutral-600">Create a personalized tale for your child</p>
          </div>
          <Button onClick={() => navigate('/children')} variant="outline">
            Manage Children
          </Button>
        </div>

        <GenerateStoryForm childId={childIdFromParams} parentId={parentIdFromParams} />

        {/* How It Works */}
        <Card className="mt-6">
          <CardHeader>
            <h2 className="text-lg font-semibold text-gray-900">How It Works</h2>
          </CardHeader>
          <CardBody>
            <ul className="space-y-2 text-sm text-neutral-600">
              <li className="flex items-start">
                <span className="text-primary-600 mr-2">•</span>
                <span>Choose your story type: child-only, hero-only, or combined adventure</span>
              </li>
              <li className="flex items-start">
                <span className="text-primary-600 mr-2">•</span>
                <span>Select a child profile you've created</span>
              </li>
              <li className="flex items-start">
                <span className="text-primary-600 mr-2">•</span>
                <span>For hero or combined stories, select a hero character</span>
              </li>
              <li className="flex items-start">
                <span className="text-primary-600 mr-2">•</span>
                <span>Choose your preferred language (English or Russian)</span>
              </li>
              <li className="flex items-start">
                <span className="text-primary-600 mr-2">•</span>
                <span>Set the desired story length (1-30 minutes)</span>
              </li>
              <li className="flex items-start">
                <span className="text-primary-600 mr-2">•</span>
                <span>Optionally specify a moral value for the story</span>
              </li>
              <li className="flex items-start">
                <span className="text-primary-600 mr-2">•</span>
                <span>Click "Generate Story" and wait for your personalized tale</span>
              </li>
            </ul>
          </CardBody>
        </Card>
      </div>
    </div>
  );
};
